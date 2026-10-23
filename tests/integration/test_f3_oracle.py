"""Integration: committed generated tests against a real Oracle + utPLSQL (``-m integration``).

Needs PLSQL_LENS_SQLPLUS (a shell command that runs sqlplus as the target schema, reading the script
on stdin) and a database prepared by docker/setup.sh. The CI job .github/workflows/oracle.yml
does both.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import pytest

from plsql_lens.testgen import SqlplusOracle, build_report, load_manifest, run_committed

pytestmark = pytest.mark.integration

ROOT = Path(__file__).resolve().parents[2]


@pytest.mark.skipif("PLSQL_LENS_SQLPLUS" not in os.environ, reason="no Oracle configured")
def test_committed_tests_compile_and_run_against_oracle(tmp_path: Path) -> None:
    targets = load_manifest(ROOT / "tests" / "fixtures" / "testgen" / "manifest.json")
    oracle = SqlplusOracle(os.environ["PLSQL_LENS_SQLPLUS"])
    results = run_committed(targets, ROOT / "tests" / "generated", oracle)
    report = build_report(results)
    (tmp_path / "report.json").write_text(json.dumps(report))
    assert report["total"]["units"] == len(targets)
    t = report["total"]
    assert (
        t["passed"] + t["failed"] + t["errored"] == t["tests"]
    )  # numbers are internally consistent
