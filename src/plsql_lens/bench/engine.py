"""Run the rule engine ("before" from a git commit, "after" = current tree) over a directory."""

from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from pathlib import Path

from .model import Found

SCRIPT = Path(__file__).resolve().parents[3] / "scripts" / "run_rules.py"


def export_src(sha: str, repo: Path, dest: Path) -> Path:
    """Export ``src/plsql_lens`` as it was at ``sha`` into ``dest`` and return the path for PYTHONPATH."""
    archive = subprocess.run(
        ["git", "-C", str(repo), "archive", sha, "src/plsql_lens"], capture_output=True, check=True
    ).stdout
    subprocess.run(["tar", "-x", "-C", str(dest)], input=archive, check=True)
    return dest / "src"


def run_engine(root: Path, files: Sequence[str] = (), src: Path | None = None) -> list[Found]:
    """Findings of the engine in ``src`` (default: the installed/current one) for files under ``root``."""
    env = dict(os.environ)
    if src is not None:
        env["PYTHONPATH"] = str(src) + os.pathsep + env.get("PYTHONPATH", "")
    proc = subprocess.run(
        [sys.executable, str(SCRIPT), str(root), *files],
        capture_output=True, text=True, env=env, check=False,
    )  # fmt: skip
    if proc.returncode != 0:
        raise RuntimeError(f"rule engine failed: {proc.stderr[-800:]}")
    return [Found(f, r, int(line)) for f, r, line in json.loads(proc.stdout)]


def run_before(sha: str, repo: Path, root: Path, files: Sequence[str] = ()) -> list[Found]:
    with tempfile.TemporaryDirectory() as tmp:
        return run_engine(root, files, export_src(sha, repo, Path(tmp)))
