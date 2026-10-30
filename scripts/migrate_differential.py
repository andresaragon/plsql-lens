"""Differential fuzzing of ``rewrite_sql``: Oracle (original) against PostgreSQL (rewritten) (F5-G1).

Generates integer ``NVL``/``DECODE`` statements (tests/differential/fuzzgen.py), rewrites each with
``plsql_lens.migrate.rewrite.rewrite_sql``, runs the fully rewritable ones in one batch per database and
compares the results by statement id. Statements the rewrite skipped on purpose are counted by reason
and not run. Nothing here calls an LLM.

    PLSQL_LENS_SQLPLUS='docker exec -i <oracle> sqlplus -s -L user/password@//localhost/FREEPDB1' \\
    PLSQL_LENS_PSQL='docker exec -i <postgres> psql -X -q -A -t -U postgres' \\
    python scripts/migrate_differential.py [--seed 20261030] [--n 2000] [--out out/differential]

Normalization as in scripts/migrate_semantics.py: Oracle prints NULL as an empty line (compared as
``<NULL>``); PostgreSQL wraps the statement in ``select coalesce(cast(x as text), '<NULL>') from (...) t(x)``.
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tests" / "differential"))

from fuzzgen import BASE, DEFAULT_N, DEFAULT_SEED, Statement, generate_statements  # noqa: E402

from plsql_lens.migrate.rewrite import rewrite_sql  # noqa: E402

NULL = "<NULL>"
MAX_N = 5000
MARK = "@@"

# Positive control: the naive rewrite of a NULL-safe comparison, the defect F5c found. DECODE(n1, n2, 1, 0)
# is 1 on Oracle (NULL matches NULL) and the plain CASE gives 0 on PostgreSQL. If the harness does not
# see this difference, "0 discrepancies" would mean nothing.
CONTROL_ID = "control-naive-decode"
CONTROL_ORACLE = BASE.format(expr="DECODE(n1, n2, 1, 0)")
CONTROL_NAIVE = (
    "SELECT CASE n1 WHEN n2 THEN 1 ELSE 0 END FROM (SELECT CAST(NULL AS INTEGER) n1, "
    "CAST(NULL AS INTEGER) n2, 1 v1, 2 v2, 2 v3, 7 v4)"
)


def oracle_script(items: list[tuple[str, str]]) -> str:
    head = (
        "set pagesize 0 feedback off heading off verify off linesize 4000 trimspool on echo off\n"
        "whenever sqlerror continue\n"
    )
    return head + "".join(f"prompt {MARK}{i}\n{sql};\n" for i, sql in items) + "exit\n"


def postgres_script(items: list[tuple[str, str]]) -> str:
    head = "\\set ON_ERROR_STOP off\n"
    body = "".join(
        f"\\echo {MARK}{i}\nselect coalesce(cast(x as text), '{NULL}') from ({sql}) t(x);\n"
        for i, sql in items
    )
    return head + body


def parse_blocks(output: str) -> dict[str, list[str]]:
    """Lines printed after each ``@@id`` marker, up to the next marker."""
    blocks: dict[str, list[str]] = {}
    current: list[str] | None = None
    for line in output.splitlines():
        if line.startswith(MARK):
            current = blocks.setdefault(line[len(MARK) :].strip(), [])
        elif current is not None:
            current.append(line)
    return blocks


def shell(var: str, command: str | None, script: str) -> str:
    if not command:
        sys.exit(f"{var} is not set (see the module docstring)")
    done = subprocess.run(shlex.split(command), input=script, capture_output=True, text=True)
    if done.returncode != 0:
        sys.exit(f"{var} failed ({done.returncode}):\n{done.stdout[-2000:]}\n{done.stderr[-2000:]}")
    return done.stdout


def oracle_value(lines: list[str]) -> tuple[str | None, str | None]:
    """(value, error): Oracle prints NULL as an empty line; errors show as ORA-/SP2- messages."""
    text = "\n".join(lines).strip()
    if "ORA-" in text or "SP2-" in text:
        return None, text.splitlines()[0][:300] if text else "empty"
    return (text or NULL), None


def postgres_value(lines: list[str]) -> tuple[str | None, str | None]:
    text = "\n".join(lines).strip("\n")
    if not lines:
        return None, "no result (the statement failed)"
    return text.strip(), None


def run(seed: int, n: int, oracle_cmd: str | None, psql_cmd: str | None) -> dict[str, Any]:
    statements: list[Statement] = generate_statements(seed, n)
    rewritten = {s.id: rewrite_sql(s.sql) for s in statements}
    runnable = [s for s in statements if rewritten[s.id].skipped == ()]
    by_reason = Counter(reason for s in statements for _, reason in rewritten[s.id].skipped)
    skipped = [s for s in statements if rewritten[s.id].skipped != ()]

    oracle_items = [(s.id, s.sql) for s in runnable] + [(CONTROL_ID, CONTROL_ORACLE)]
    pg_items = [(s.id, rewritten[s.id].sql) for s in runnable] + [(CONTROL_ID, CONTROL_NAIVE)]
    oracle_out = shell("PLSQL_LENS_SQLPLUS", oracle_cmd, oracle_script(oracle_items))
    pg_out = shell("PLSQL_LENS_PSQL", psql_cmd, postgres_script(pg_items))
    ora, pg = parse_blocks(oracle_out), parse_blocks(pg_out)

    matches = 0
    values: Counter[str] = Counter()
    discrepancies: list[dict[str, str]] = []
    oracle_errors: list[dict[str, str]] = []
    postgres_errors: list[dict[str, str]] = []
    for s in runnable:
        o_val, o_err = oracle_value(ora.get(s.id, []))
        p_val, p_err = postgres_value(pg.get(s.id, []))
        record = {"id": s.id, "original": s.sql, "rewritten": rewritten[s.id].sql}
        if o_err:
            oracle_errors.append({**record, "error": o_err})
        if p_err:
            postgres_errors.append({**record, "error": p_err})
        if o_err or p_err:
            continue
        if o_val == p_val:
            matches += 1
            values[str(o_val)] += 1
        else:
            discrepancies.append({**record, "oracle": str(o_val), "postgres": str(p_val)})
    discrepancies.sort(key=lambda d: (len(d["original"]), d["id"]))
    c_ora, _ = oracle_value(ora.get(CONTROL_ID, []))
    c_pg, _ = postgres_value(pg.get(CONTROL_ID, []))
    control = {
        "id": CONTROL_ID,
        "original": CONTROL_ORACLE,
        "naive": CONTROL_NAIVE,
        "oracle": c_ora,
        "postgres": c_pg,
        "detected": c_ora is not None and c_pg is not None and c_ora != c_pg,
    }
    return {
        "seed": seed,
        "n": n,
        "generated": len(statements),
        "rewritable": len(runnable),
        "rewritable_pct": round(100 * len(runnable) / max(1, len(statements)), 1),
        "skipped_by_rewrite": {
            "count": len(skipped),
            "by_reason": dict(sorted(by_reason.items())),
            "examples": [
                {"id": s.id, "sql": s.sql, "skipped": [list(x) for x in rewritten[s.id].skipped]}
                for s in skipped[:5]
            ],
        },
        "executed": len(runnable),
        "oracle_errors": oracle_errors,
        "postgres_errors": postgres_errors,
        "matches": matches,
        "value_distribution": dict(sorted(values.items(), key=lambda kv: (-kv[1], kv[0]))),
        "discrepancies": discrepancies,
        "control": control,
    }


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--seed", type=int, default=DEFAULT_SEED)
    ap.add_argument("--n", type=int, default=DEFAULT_N)
    ap.add_argument("--out", type=Path, default=ROOT / "out" / "differential")
    args = ap.parse_args(argv)
    if not 1 <= args.n <= MAX_N:
        sys.exit(f"--n must be between 1 and {MAX_N}")
    results = run(
        args.seed, args.n, os.environ.get("PLSQL_LENS_SQLPLUS"), os.environ.get("PLSQL_LENS_PSQL")
    )
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "results.json").write_text(json.dumps(results, indent=2) + "\n")
    summary = {
        k: v
        for k, v in results.items()
        if k not in ("discrepancies", "oracle_errors", "postgres_errors")
    }
    summary["skipped_by_rewrite"] = {
        "count": results["skipped_by_rewrite"]["count"],
        "by_reason": results["skipped_by_rewrite"]["by_reason"],
    }
    summary.update(
        oracle_errors=len(results["oracle_errors"]),
        postgres_errors=len(results["postgres_errors"]),
        discrepancies=len(results["discrepancies"]),
    )
    print(json.dumps(summary, indent=2))
    print("control (naive CASE for DECODE(n1, n2, 1, 0)):", json.dumps(results["control"]))
    for d in results["discrepancies"][:10]:
        print(
            f"DISCREPANCY {d['id']}: oracle={d['oracle']} postgres={d['postgres']}\n  {d['original']}\n  {d['rewritten']}"
        )
    if not results["control"]["detected"]:
        print(
            "the control difference was NOT seen: the comparison cannot be trusted", file=sys.stderr
        )
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
