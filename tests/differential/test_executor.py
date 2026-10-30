"""The differential executor against fake ``sqlplus``/``psql`` commands (no database, F5-G1)."""

from __future__ import annotations

import importlib.util
import json
import sys
import textwrap
from pathlib import Path
from types import ModuleType

import pytest
from fuzzgen import generate_statements

from plsql_lens.migrate.rewrite import rewrite_sql

ROOT = Path(__file__).resolve().parents[2]


def load_script() -> ModuleType:
    spec = importlib.util.spec_from_file_location(
        "migrate_differential", ROOT / "scripts" / "migrate_differential.py"
    )
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules["migrate_differential"] = mod
    spec.loader.exec_module(mod)
    return mod


FAKE = textwrap.dedent(
    '''
    """Fake sqlplus/psql: reads the script on stdin, prints a marker and a value per statement."""
    import sys

    kind, overrides = sys.argv[1], dict(a.split("=", 1) for a in sys.argv[2:])
    for line in sys.stdin:
        line = line.rstrip("\\n")
        if kind == "oracle" and line.startswith("prompt @@"):
            sid = line[len("prompt "):]
        elif kind == "postgres" and line.startswith("\\\\echo @@"):
            sid = line[len("\\\\echo "):]
        else:
            continue
        key = sid[2:]
        print(sid)
        mode = overrides.get(key, "")
        if mode == "error":
            if kind == "oracle":
                print("ORA-00932: inconsistent datatypes")
            continue
        if mode == "null":
            print("" if kind == "oracle" else "<NULL>")
        elif mode.startswith("value:"):
            print(mode[6:])
        else:
            print("5")
    '''
)


@pytest.fixture
def fakes(tmp_path: Path) -> tuple[Path, str]:
    path = tmp_path / "fake_db.py"
    path.write_text(FAKE)
    return path, sys.executable


CONTROL = "control-naive-decode"


def cmd(py: str, path: Path, kind: str, **overrides: str) -> str:
    """The fake command; by default the control statement differs (Oracle 1, PostgreSQL 0)."""
    default = {CONTROL: "value:1" if kind == "oracle" else "value:0"}
    merged = {**default, **overrides}
    return " ".join([py, str(path), kind, *(f"{k}={v}" for k, v in merged.items())])


def test_the_script_runs_end_to_end_with_matches_discrepancies_and_errors(
    fakes: tuple[Path, str], tmp_path: Path
) -> None:
    mod = load_script()
    path, py = fakes
    stmts = generate_statements(7, 60)
    rewritable = [s for s in stmts if rewrite_sql(s.sql).skipped == ()]
    skipped = [s for s in stmts if rewrite_sql(s.sql).skipped != ()]
    assert len(rewritable) >= 6 and skipped, "the sample must mix rewritable and skipped statements"
    a, b, c, d, e = (s.id for s in rewritable[:5])
    results = mod.run(
        seed=7,
        n=60,
        oracle_cmd=cmd(py, path, "oracle", **{a: "value:9", b: "error", c: "null"}),
        psql_cmd=cmd(py, path, "postgres", **{a: "value:4", d: "error", c: "null"}),
    )
    assert results["seed"] == 7 and results["n"] == 60 and results["generated"] == 60
    assert results["rewritable"] == len(rewritable)
    assert results["skipped_by_rewrite"]["count"] == len(skipped)
    assert sum(results["skipped_by_rewrite"]["by_reason"].values()) >= len(skipped)
    assert results["executed"] == len(rewritable)
    assert [x["id"] for x in results["oracle_errors"]] == [b]
    assert [x["id"] for x in results["postgres_errors"]] == [d]
    # `a` differs (9 vs 4); `c` is NULL on both (Oracle prints it empty); the rest match at 5
    assert [x["id"] for x in results["discrepancies"]] == [a]
    disc = results["discrepancies"][0]
    assert disc["oracle"] == "9" and disc["postgres"] == "4"
    assert disc["original"].startswith("SELECT ") and "NVL(" not in disc[
        "rewritten"
    ].upper().replace("COALESCE", "")
    assert results["matches"] == len(rewritable) - 3
    assert e  # the fifth statement exists and matched


def test_oracle_empty_output_equals_the_postgres_null_marker(fakes: tuple[Path, str]) -> None:
    mod = load_script()
    path, py = fakes
    rewritable = [s for s in generate_statements(3, 30) if rewrite_sql(s.sql).skipped == ()]
    sid = rewritable[0].id
    results = mod.run(
        seed=3,
        n=30,
        oracle_cmd=cmd(py, path, "oracle", **{sid: "null"}),
        psql_cmd=cmd(py, path, "postgres", **{sid: "null"}),
    )
    assert results["discrepancies"] == [] and results["matches"] == results["executed"]


def test_discrepancies_are_listed_shortest_first(fakes: tuple[Path, str]) -> None:
    mod = load_script()
    path, py = fakes
    stmts = [s for s in generate_statements(5, 80) if rewrite_sql(s.sql).skipped == ()]
    ids = [s.id for s in stmts[:8]]
    results = mod.run(
        seed=5,
        n=80,
        oracle_cmd=cmd(py, path, "oracle"),
        psql_cmd=cmd(py, path, "postgres", **{i: "value:1" for i in ids}),
    )
    lengths = [len(d["original"]) for d in results["discrepancies"]]
    assert len(lengths) == 8 and lengths == sorted(lengths)


def test_main_writes_results_json_and_refuses_a_missing_command_or_a_huge_n(
    fakes: tuple[Path, str], tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    mod = load_script()
    path, py = fakes
    out = tmp_path / "out"
    monkeypatch.setenv("PLSQL_LENS_SQLPLUS", cmd(py, path, "oracle"))
    monkeypatch.setenv("PLSQL_LENS_PSQL", cmd(py, path, "postgres"))
    assert mod.main(["--seed", "11", "--n", "40", "--out", str(out)]) == 0
    doc = json.loads((out / "results.json").read_text())
    assert doc["seed"] == 11 and doc["n"] == 40 and doc["discrepancies"] == []
    with pytest.raises(SystemExit):
        mod.main(["--n", "5001", "--out", str(out)])
    monkeypatch.delenv("PLSQL_LENS_PSQL")
    with pytest.raises(SystemExit):
        mod.main(["--n", "10", "--out", str(out)])


def test_the_control_is_the_known_naive_rewrite_and_must_be_seen_to_differ(
    fakes: tuple[Path, str],
) -> None:
    mod = load_script()
    path, py = fakes
    assert mod.CONTROL_ID == CONTROL
    results = mod.run(
        seed=2, n=20, oracle_cmd=cmd(py, path, "oracle"), psql_cmd=cmd(py, path, "postgres")
    )
    c = results["control"]
    assert c["id"] == CONTROL and c["detected"] is True
    assert c["oracle"] == "1" and c["postgres"] == "0"
    assert "DECODE(n1, n2, 1, 0)" in c["original"]
    assert "CASE n1 WHEN n2 THEN 1 ELSE 0 END" in c["naive"]
    # the control is not part of the fuzzing counts
    assert results["executed"] == results["rewritable"]
    assert all(d["id"] != CONTROL for d in results["discrepancies"])


def test_a_harness_that_cannot_see_the_control_difference_fails_the_run(
    fakes: tuple[Path, str], tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    mod = load_script()
    path, py = fakes
    same = {CONTROL: "value:1"}
    monkeypatch.setenv("PLSQL_LENS_SQLPLUS", cmd(py, path, "oracle", **same))
    monkeypatch.setenv("PLSQL_LENS_PSQL", cmd(py, path, "postgres", **same))
    assert mod.main(["--n", "10", "--out", str(tmp_path)]) == 3
    assert json.loads((tmp_path / "results.json").read_text())["control"]["detected"] is False


def test_the_distribution_of_matched_values_is_reported(fakes: tuple[Path, str]) -> None:
    mod = load_script()
    path, py = fakes
    results = mod.run(
        seed=4, n=30, oracle_cmd=cmd(py, path, "oracle"), psql_cmd=cmd(py, path, "postgres")
    )
    dist = results["value_distribution"]
    assert sum(dist.values()) == results["matches"] and dist == {"5": results["matches"]}
