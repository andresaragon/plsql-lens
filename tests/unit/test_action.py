"""The composite GitHub Action (`action.yml`) and its docs, checked without GitHub."""

from __future__ import annotations

import json
import os
import re
import stat
import subprocess
import sys
from pathlib import Path
from typing import Any

import pytest
import yaml
from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parents[2]
ACTION = ROOT / "action.yml"
DOC = ROOT / "docs" / "github-action.md"
SELFTEST = ROOT / ".github" / "workflows" / "action-selftest.yml"
SCHEMA = json.loads((ROOT / "tests" / "vendor" / "sarif-2.1.0.json").read_text())

INPUTS = {"path", "fail-on", "rules", "sarif-file", "upload"}


def _action() -> dict[str, Any]:
    doc = yaml.safe_load(ACTION.read_text())
    assert isinstance(doc, dict)
    return doc


def _steps() -> list[dict[str, Any]]:
    return list(_action()["runs"]["steps"])


def _review_step() -> dict[str, Any]:
    steps = [s for s in _steps() if "plsql-lens" in s.get("run", "")]
    assert len(steps) == 1, "exactly one step runs plsql-lens"
    return steps[0]


def _expand(value: str, inputs: dict[str, str]) -> str:
    def sub(m: re.Match[str]) -> str:
        expr = m.group(1).strip()
        if expr == "github.action_path":
            return str(ROOT)
        if expr.startswith("inputs."):
            return inputs[expr.removeprefix("inputs.")]
        raise AssertionError(f"unexpected expression in the review step env: {expr}")

    return re.sub(r"\$\{\{(.*?)\}\}", sub, value)


def _run_review_step(
    tmp_path: Path, **overrides: str
) -> tuple[subprocess.CompletedProcess[str], Path]:
    """Run the action's own `plsql-lens` step in bash, with the inputs defaulted as declared."""
    declared = _action()["inputs"]
    inputs = {name: str(spec.get("default", "")) for name, spec in declared.items()}
    inputs["path"] = str(ROOT / "corpus" / "logger")
    inputs["sarif-file"] = str(tmp_path / "out.sarif")
    inputs.update(overrides)
    step = _review_step()
    env = {k: _expand(str(v), inputs) for k, v in step.get("env", {}).items()}
    # Offline stand-in for `uvx --from <checkout> plsql-lens`: it drops those 3 arguments
    # and runs the entry point already installed in this environment.
    shim = tmp_path / "bin" / "uvx"
    shim.parent.mkdir()
    entry = Path(sys.executable).parent / "plsql-lens"
    shim.write_text(f'#!/bin/sh\nshift 3\nexec "{entry}" "$@"\n')
    shim.chmod(shim.stat().st_mode | stat.S_IXUSR)
    full_env = {**os.environ, **env, "PATH": f"{shim.parent}{os.pathsep}{os.environ['PATH']}"}
    shell = step.get("shell", "bash")
    assert shell == "bash"
    proc = subprocess.run(
        ["bash", "-e", "-c", step["run"]],
        env=full_env,
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    return proc, Path(inputs["sarif-file"])


def _sarif_errors(doc: object) -> list[str]:
    validator = Draft202012Validator(SCHEMA)
    return [f"{'/'.join(map(str, e.path))}: {e.message}" for e in validator.iter_errors(doc)]


# --- action.yml ---------------------------------------------------------------------------


def test_action_is_composite() -> None:
    assert _action()["runs"]["using"] == "composite"


def test_action_has_the_five_inputs_each_described() -> None:
    inputs = _action()["inputs"]
    assert set(inputs) == INPUTS
    for name, spec in inputs.items():
        assert str(spec.get("description", "")).strip(), f"input {name} has no description"


def test_upload_is_off_by_default() -> None:
    assert str(_action()["inputs"]["upload"]["default"]).lower() == "false"


def test_action_carries_no_secrets_or_tokens() -> None:
    text = ACTION.read_text().lower()
    assert "secrets." not in text
    assert "token" not in text


def test_every_uses_is_pinned_to_a_version() -> None:
    uses = [s["uses"] for s in _steps() if "uses" in s]
    assert uses, "the action is expected to use at least one published action"
    for ref in uses:
        _, _, version = ref.partition("@")
        assert re.fullmatch(r"v\d+(\.\d+){0,2}|[0-9a-f]{40}", version), f"{ref} is not pinned"


def test_installs_from_its_own_checkout_not_pypi() -> None:
    text = ACTION.read_text()
    assert "github.action_path" in text or "GITHUB_ACTION_PATH" in text
    assert "pip install" not in text


def test_review_step_passes_user_input_through_env_not_the_script() -> None:
    step = _review_step()
    assert "${{" not in step["run"], "inputs must reach the script through env, not interpolation"


def test_upload_runs_even_if_review_failed_and_only_when_requested() -> None:
    upload = [s for s in _steps() if "upload-sarif" in s.get("uses", "")]
    assert len(upload) == 1
    condition = str(upload[0]["if"])
    assert "always()" in condition
    assert "inputs.upload" in condition
    assert upload[0]["with"]["sarif_file"] == "${{ inputs.sarif-file }}"


# --- the command the action builds, run locally ---------------------------------------------


def test_command_on_corpus_logger_writes_schema_valid_sarif(tmp_path: Path) -> None:
    proc, sarif = _run_review_step(tmp_path)
    assert proc.returncode == 0, proc.stderr
    doc = json.loads(sarif.read_text())
    assert doc["version"] == "2.1.0"
    assert doc["runs"][0]["results"], "corpus/logger is expected to have findings"
    assert _sarif_errors(doc) == []


def test_fail_on_exits_1_but_still_leaves_valid_sarif(tmp_path: Path) -> None:
    proc, sarif = _run_review_step(tmp_path, **{"fail-on": "high"})
    assert proc.returncode == 1, proc.stderr
    assert _sarif_errors(json.loads(sarif.read_text())) == []


def test_rules_input_restricts_the_rules(tmp_path: Path) -> None:
    proc, sarif = _run_review_step(tmp_path, rules="PLL001")
    assert proc.returncode == 0, proc.stderr
    ids = {r["ruleId"] for r in json.loads(sarif.read_text())["runs"][0]["results"]}
    assert ids <= {"PLL001"}


def test_unknown_rule_is_a_usage_error(tmp_path: Path) -> None:
    proc, _ = _run_review_step(tmp_path, rules="NOPE")
    assert proc.returncode == 2


# --- docs/github-action.md ------------------------------------------------------------------


def _doc_yaml_blocks() -> list[str]:
    return re.findall(r"```yaml\n(.*?)```", DOC.read_text(), flags=re.DOTALL)


def test_docs_have_at_least_one_workflow_example_that_parses() -> None:
    blocks = _doc_yaml_blocks()
    assert blocks
    workflows = []
    for block in blocks:
        parsed = yaml.safe_load(block)
        assert isinstance(parsed, dict)
        if "jobs" in parsed:
            workflows.append(parsed)
    assert workflows, "docs must include a full workflow example"
    for wf in workflows:
        # YAML 1.1 reads the bare key `on` as the boolean True.
        assert "on" in wf or True in wf
        steps = [s for job in wf["jobs"].values() for s in job["steps"]]
        assert any(str(s.get("uses", "")).startswith("./") or "plsql-lens" in str(s) for s in steps)


def test_docs_document_every_input() -> None:
    text = DOC.read_text()
    for name in INPUTS:
        assert f"`{name}`" in text, f"input {name} is not documented"


# --- .github/workflows/action-selftest.yml --------------------------------------------------


def test_selftest_uses_the_local_action_on_corpus_logger_without_upload() -> None:
    wf = yaml.safe_load(SELFTEST.read_text())
    steps = [s for job in wf["jobs"].values() for s in job["steps"]]
    local = [s for s in steps if s.get("uses") == "./"]
    assert local, "the self-test must run the action from this checkout"
    for step in local:
        assert step["with"]["path"] == "corpus/logger"
        assert str(step["with"]["upload"]).lower() == "false"
    for step in steps:
        if "uses" in step and step["uses"] != "./":
            assert re.search(r"@v\d", step["uses"]), f"{step['uses']} is not pinned"


@pytest.mark.parametrize("text", [ACTION.read_text(), SELFTEST.read_text()])
def test_no_upload_enabled_anywhere_in_tests_or_selftest(text: str) -> None:
    assert not re.search(r"upload:\s*['\"]?true", text)
