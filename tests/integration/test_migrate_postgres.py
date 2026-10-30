"""Integration: the F5b rewrites run on a real PostgreSQL 16 (``-m integration``).

Needs PLSQL_LENS_PSQL, a shell command that runs ``psql`` and reads the script on stdin, for
example ``psql -X -q -A -t -v ON_ERROR_STOP=1 -h localhost -U postgres`` (the job
.github/workflows/postgres.yml starts the server and sets it). Without it the tests are skipped.

For each case of tests/fixtures/migrate/semantics.json the rewritten statement is run (after the
case's ``setup``) and compared with the result observed on Oracle (``oracle_result``). The five
cases labelled ``known_divergence`` must give ``pg_naive_result`` and differ from
``oracle_result``. If PLSQL_LENS_MIGRATE_RESULTS names a file, a JSON report of every case is
written there.
"""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
from pathlib import Path
from typing import Any

import pytest

from plsql_lens.migrate.rewrite import rewrite_sql

pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif("PLSQL_LENS_PSQL" not in os.environ, reason="no PostgreSQL configured"),
]

ROOT = Path(__file__).resolve().parents[2]
DATA = json.loads((ROOT / "tests" / "fixtures" / "migrate" / "semantics.json").read_text())
NULL = DATA["null_marker"]
CASES: list[dict[str, Any]] = DATA["cases"]
_RESULTS: list[dict[str, Any]] = []


def psql(script: str) -> str:
    done = subprocess.run(
        shlex.split(os.environ["PLSQL_LENS_PSQL"]), input=script, capture_output=True, text=True
    )
    assert done.returncode == 0, f"psql failed:\n{done.stdout}\n{done.stderr}"
    return done.stdout.strip("\n")


def run_on_postgres(setup: list[str], sql: str) -> str:
    names = [m.group(1) for s in setup if (m := re.match(r"create sequence (\w+)", s))]
    drops = "".join(f"drop sequence if exists {n};\n" for n in names)
    wrapped = f"select coalesce(cast(x as text), '{NULL}') from ({sql}) t(x)"
    script = drops + "".join(f"{s};\n" for s in setup) + f"{wrapped};\n" + drops
    return psql(script)


def test_postgres_is_version_16() -> None:
    assert psql("show server_version;").startswith("16.")


@pytest.mark.parametrize("case", CASES, ids=[c["id"] for c in CASES])
def test_rewritten_statement_gives_the_oracle_result_on_postgres(case: dict[str, Any]) -> None:
    rewritten = rewrite_sql(case["oracle_sql"])
    assert rewritten.skipped == (), "the case is expected to be fully rewritable"
    got = run_on_postgres(case["setup"], rewritten.sql)
    div = case.get("known_divergence")
    record = {
        "id": case["id"],
        "construct": case["construct"],
        "oracle_sql": case["oracle_sql"],
        "rewritten_sql": rewritten.sql,
        "applied": list(rewritten.applied),
        "oracle_result": case["oracle_result"],
        "postgres_result": got,
        "known_divergence": div,
    }
    if div:
        record["status"] = (
            "divergent as documented"
            if (got == div["pg_naive_result"] and got != case["oracle_result"])
            else "UNEXPECTED"
        )
    else:
        record["status"] = "match" if got == case["oracle_result"] else "MISMATCH"
    _RESULTS.append(record)
    if div:
        assert got == div["pg_naive_result"], f"{case['id']}: {got!r}"
        assert got != case["oracle_result"], f"{case['id']}: unexpectedly equal to Oracle"
    else:
        assert got == case["oracle_result"], (
            f"{case['id']}: oracle={case['oracle_result']!r} postgres={got!r} sql={rewritten.sql!r}"
        )


def test_zz_write_the_results_report() -> None:
    out = os.environ.get("PLSQL_LENS_MIGRATE_RESULTS")
    if not out:
        pytest.skip("PLSQL_LENS_MIGRATE_RESULTS is not set")
    summary = {
        "cases": len(_RESULTS),
        "match": sum(r["status"] == "match" for r in _RESULTS),
        "divergent_as_documented": sum(r["status"] == "divergent as documented" for r in _RESULTS),
        "mismatch": [r["id"] for r in _RESULTS if r["status"] == "MISMATCH"],
        "unexpected": [r["id"] for r in _RESULTS if r["status"] == "UNEXPECTED"],
        "postgres": psql("show server_version;"),
    }
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    Path(out).write_text(json.dumps({"summary": summary, "cases": _RESULTS}, indent=2) + "\n")
    assert len(_RESULTS) == len(CASES), "run the whole file so the report is complete"
