"""The distributable package and the project files (issue #15).

Metadata and project-file checks run everywhere. The build checks need ``uv`` and network access
(build isolation downloads hatchling; the clean venv downloads typer), so they are skipped without
them.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import tarfile
import tomllib
import urllib.request
import zipfile
from pathlib import Path

import pytest
import yaml

ROOT = Path(__file__).resolve().parents[2]
PYPROJECT = tomllib.loads((ROOT / "pyproject.toml").read_text())
REPO_URL = "https://github.com/andresaragon/plsql-lens"
FIXTURE = ROOT / "tests" / "fixtures" / "shop.pkb"

WHEEL_FORBIDDEN = ("corpus/", "docs/", "tests/", "spikes/")
SDIST_FORBIDDEN = ("corpus/", "docs/benchmarks/", "tests/", "spikes/", ".hypothesis/", ".github/")


# --- metadata (no build needed) -----------------------------------------------------------------


def test_version_and_dependencies_are_unchanged() -> None:
    project = PYPROJECT["project"]
    assert project["version"] == "0.1.0"
    assert project["dependencies"] == ["typer>=0.12"]


def test_project_metadata_has_urls_classifiers_and_keywords() -> None:
    project = PYPROJECT["project"]
    urls = project["urls"]
    assert urls["Repository"] == REPO_URL
    assert all(u.startswith(REPO_URL) for u in urls.values())
    classifiers = project["classifiers"]
    assert "Development Status :: 3 - Alpha" in classifiers
    assert not any("Production/Stable" in c or "Mature" in c for c in classifiers)
    assert "Typing :: Typed" in classifiers
    assert "License :: OSI Approved :: MIT License" in classifiers
    assert project["keywords"]


def test_no_package_data_beyond_the_source_tree_is_declared_for_the_wheel() -> None:
    wheel = PYPROJECT["tool"]["hatch"]["build"]["targets"]["wheel"]
    assert wheel["packages"] == ["src/plsql_lens"]


def test_py_typed_marker_is_in_the_source_tree() -> None:
    assert (ROOT / "src" / "plsql_lens" / "py.typed").is_file()


# --- project files ------------------------------------------------------------------------------


def test_changelog_follows_keep_a_changelog_and_links_the_phase_reports() -> None:
    text = (ROOT / "CHANGELOG.md").read_text()
    assert "keepachangelog.com" in text
    assert re.search(r"^## \[Unreleased\]", text, flags=re.MULTILINE)
    assert not re.search(r"\d{4}-\d{2}-\d{2}", text), "no dates: they are not in the reports"
    reports = sorted((ROOT / "docs" / "reports").glob("phase-*.md"))
    assert reports
    for report in reports:
        assert f"docs/reports/{report.name}" in text, f"{report.name} is not linked"
    for link in re.findall(r"\]\((docs/[^)#]+)", text):
        assert (ROOT / link).exists(), f"broken link {link}"
    for phase in ("F1", "F2", "F3", "F4", "F4b"):
        assert re.search(rf"\b{phase}\b", text), f"{phase} is not summarized"


def test_contributing_uses_the_real_commands() -> None:
    text = (ROOT / "CONTRIBUTING.md").read_text()
    for command in (
        "uv sync",
        "uv run ruff check .",
        "uv run ruff format --check .",
        "uv run mypy",
        "uv run pytest --cov=plsql_lens --cov-fail-under=85",
        "make test",
        "make lint",
    ):
        assert command in text, f"{command!r} is not mentioned"


def test_contributing_names_the_frozen_files() -> None:
    text = (ROOT / "CONTRIBUTING.md").read_text()
    assert "test_external_frozen" in text


def test_security_policy_uses_github_private_reporting_and_no_email() -> None:
    text = (ROOT / "SECURITY.md").read_text()
    assert "Report a vulnerability" in text
    assert "@" not in text, "no e-mail address in the security policy"
    assert f"{REPO_URL}/security" in text


def test_ci_has_a_build_job_that_runs_twine_check() -> None:
    wf = yaml.safe_load((ROOT / ".github" / "workflows" / "ci.yml").read_text())
    assert "checks" in wf["jobs"], "the existing job must stay"
    steps = wf["jobs"]["build"]["steps"]
    commands = " ".join(str(s.get("run", "")) for s in steps)
    assert "uv build" in commands
    assert "twine check" in commands
    assert "pytest" not in commands or "test_packaging" in commands


# --- the built package (needs uv and network) ---------------------------------------------------

needs_uv = pytest.mark.skipif(shutil.which("uv") is None, reason="uv is not installed")


def _online() -> bool:
    try:
        urllib.request.urlopen("https://pypi.org/simple/hatchling/", timeout=10).close()
    except Exception:
        return False
    return True


@pytest.fixture(scope="module")
def dist(tmp_path_factory: pytest.TempPathFactory) -> Path:
    if not _online():
        pytest.skip("no network: build isolation and the clean venv need the package index")
    out = tmp_path_factory.mktemp("dist")
    # Build from a copy of the non-ignored files so local junk (.hypothesis, caches) cannot leak in.
    src = tmp_path_factory.mktemp("src")
    files = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        capture_output=True,
        check=True,
    ).stdout.split(b"\0")
    for rel in filter(None, (f.decode() for f in files)):
        if (ROOT / rel).is_file():
            (src / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / rel, src / rel)
    subprocess.run(
        ["uv", "build", "--out-dir", str(out), str(src)], check=True, capture_output=True
    )
    return out


def _wheel(dist: Path) -> Path:
    (wheel,) = dist.glob("*.whl")
    return wheel


def _sdist(dist: Path) -> Path:
    (sdist,) = dist.glob("*.tar.gz")
    return sdist


@needs_uv
def test_uv_build_makes_an_sdist_and_a_wheel(dist: Path) -> None:
    assert _wheel(dist).name.startswith("plsql_lens-0.1.0-")
    assert _sdist(dist).name == "plsql_lens-0.1.0.tar.gz"


@needs_uv
def test_wheel_has_py_typed_no_dev_trees_and_is_small(dist: Path) -> None:
    wheel = _wheel(dist)
    names = zipfile.ZipFile(wheel).namelist()
    assert "plsql_lens/py.typed" in names
    for prefix in WHEEL_FORBIDDEN:
        assert not any(n.startswith(prefix) or f"/{prefix}" in n for n in names), prefix
    assert wheel.stat().st_size < 1_000_000


@needs_uv
def test_sdist_leaves_out_the_corpus_benchmarks_tests_and_spikes(dist: Path) -> None:
    with tarfile.open(_sdist(dist)) as tar:
        names = [n.split("/", 1)[1] for n in tar.getnames() if "/" in n]
    for prefix in SDIST_FORBIDDEN:
        assert not any(n.startswith(prefix) for n in names), prefix
    for required in ("pyproject.toml", "README.md", "LICENSE", "NOTICE", "CHANGELOG.md"):
        assert required in names
    assert any(n.startswith("src/plsql_lens/") for n in names)
    assert "src/plsql_lens/py.typed" in names


@needs_uv
def test_wheel_installs_in_a_clean_venv_and_reviews_a_fixture(dist: Path, tmp_path: Path) -> None:
    venv = tmp_path / "venv"
    subprocess.run(["uv", "venv", "--seed", str(venv)], check=True, capture_output=True)
    bindir = venv / ("Scripts" if os.name == "nt" else "bin")
    env = {k: v for k, v in os.environ.items() if k not in ("VIRTUAL_ENV", "PYTHONPATH")}
    subprocess.run(
        [str(bindir / "python"), "-m", "pip", "install", "--quiet", str(_wheel(dist))],
        check=True,
        capture_output=True,
        env=env,
    )
    exe = bindir / ("plsql-lens.exe" if os.name == "nt" else "plsql-lens")
    proc = subprocess.run(
        [str(exe), "review", str(FIXTURE), "--format", "json"],
        capture_output=True,
        text=True,
        cwd=tmp_path,  # not the repo: the installed package must work on its own
        env=env,
        check=False,
    )
    assert proc.returncode == 0, proc.stderr
    report = json.loads(proc.stdout)
    assert report["findings"], "the shop fixture is expected to produce findings"
