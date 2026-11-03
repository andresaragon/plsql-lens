"""MIG012-MIG017 (F5-G4): written from docs/migration-rules.md, not from the implementation."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.migrate import MIGRATION_RULES, migrate_file, migrate_source
from plsql_lens.migrate.output import to_sarif

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "tests" / "fixtures" / "migrate" / "rules"
CONTRACT = (ROOT / "docs" / "migration-rules.md").read_text()
SCHEMA = json.loads((ROOT / "tests" / "vendor" / "sarif-2.1.0.json").read_text())
NEW = [f"MIG{i:03d}" for i in range(12, 18)]
run = CliRunner().invoke


def hits(src: str, rule: str) -> list[tuple[int, int]]:
    return [(f.location.line, f.location.col) for f in migrate_source(src, "x.sql", [rule])]


# --- locations: the token named in the contract -----------------------------------------------


@pytest.mark.parametrize(
    ("src", "rule", "col"),
    [
        ("select a bulk collect into b from t;", "MIG012", 10),  # the bulk token
        ("  forall i in 1 .. 3 delete from t;", "MIG013", 3),
        ("  execute immediate 'x';", "MIG014", 3),  # the execute token
        ("  raise_application_error(-20001, 'x');", "MIG015", 3),
        ("  utl_file.fclose(f);", "MIG016", 3),
        ("  x := sys.dbms_lob.getlength(c);", "MIG016", 8),  # the sys token, as MIG009
        ("function f return t pipelined is", "MIG017", 21),
    ],
)
def test_locations_point_at_the_token_named_in_the_contract(src: str, rule: str, col: int) -> None:
    assert hits(src, rule) == [(1, col)]


# --- token definitions ------------------------------------------------------------------------


def test_bulk_and_execute_need_their_second_word_immediately_after() -> None:
    assert hits("bulk\n  -- c\n collect into x", "MIG012") == [(1, 1)]
    assert not hits("bulk into collect", "MIG012")
    assert hits("execute /* c */ immediate 'x'", "MIG014") == [(1, 1)]
    assert not hits("execute 'x'; immediate", "MIG014")


def test_forall_and_pipelined_are_whole_identifiers() -> None:
    assert not hits("forall_count := 1; l_forall := 2;", "MIG013")
    assert not hits("pipelined_count := 1;", "MIG017")
    assert len(hits("FORALL i IN 1..2 x; forall j IN 1..2 y;", "MIG013")) == 2


def test_raise_application_error_is_a_call_not_preceded_by_a_dot() -> None:
    assert len(hits("raise_application_error(-20000, 'x');", "MIG015")) == 1
    assert not hits("my_pkg.raise_application_error(-20000, 'x');", "MIG015")
    assert not hits("raise_application_error := 1;", "MIG015")


@pytest.mark.parametrize(
    "src",
    [
        "my_pkg.dbms_lob.x(1);",
        "dbms_lobby.x(1);",
        "x.sys.dbms_sql.open_cursor;",
        "grant execute on dbms_lob to u;",  # no `.identifier` after the package
        "x := utl_file;",
        "x := 'utl_file.fopen';  -- dbms_sql.parse",
    ],
)
def test_mig016_negatives(src: str) -> None:
    assert not hits(src, "MIG016")


def test_mig016_takes_types_and_constants_not_only_calls() -> None:
    assert len(hits("f utl_file.file_type; n := dbms_lob.lob_readonly;", "MIG016")) == 2


def test_nothing_inside_strings_or_comments_is_a_match() -> None:
    src = (
        "x := 'bulk collect forall execute immediate raise_application_error( pipelined';\n"
        "-- bulk collect forall execute immediate raise_application_error( utl_file.f pipelined\n"
        "/* dbms_sql.x dbms_lob.y */\n"
    )
    for rule in NEW:
        assert not hits(src, rule), rule


# --- severity ---------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("pkg", "severity"),
    [("dbms_sql", "high"), ("utl_file", "high"), ("dbms_lob", "medium")],
)
def test_mig016_severity_is_decided_by_the_package(pkg: str, severity: str) -> None:
    for prefix in ("", "sys."):
        (f,) = migrate_source(f"x := {prefix}{pkg}.m(1);", "x.sql", ["MIG016"])
        assert f.severity == severity, (prefix, pkg)
    assert MIGRATION_RULES["MIG016"].severity == "high"


def test_mig016_message_names_the_package() -> None:
    for pkg in ("dbms_sql", "utl_file", "dbms_lob"):
        (f,) = migrate_source(f"x := {pkg}.m(1);", "x.sql", ["MIG016"])
        assert pkg.upper() in f.message


@pytest.mark.parametrize("rule", ["MIG012", "MIG013", "MIG014", "MIG015", "MIG017"])
def test_the_other_new_rules_give_every_finding_the_rule_severity(rule: str) -> None:
    findings = [f for p in sorted((FIXTURES / rule).glob("pos_*.pkb")) for f in migrate_file(p)]
    ours = [f for f in findings if f.rule_id == rule]
    assert ours and {f.severity for f in ours} == {"medium"}


# --- finding text -----------------------------------------------------------------------------


def test_mig014_message_says_the_dynamic_sql_is_not_analyzed() -> None:
    (f,) = migrate_source("execute immediate 'select 1';", "x.sql", ["MIG014"])
    assert "not analyzed" in f.message.lower() or "not analyzed" in f.rationale.lower()
    assert "format" in (f.fix_hint or "").lower() and "$1" in (f.fix_hint or "")


def test_mig015_and_mig017_hints_name_the_postgresql_construct() -> None:
    (a,) = migrate_source("raise_application_error(-20001, 'x');", "x.sql", ["MIG015"])
    assert "RAISE EXCEPTION" in (a.fix_hint or "") and "ERRCODE" in (a.fix_hint or "")
    (b,) = migrate_source("function f return t pipelined is", "x.sql", ["MIG017"])
    assert "SETOF" in (b.fix_hint or "") or "RETURNS TABLE" in (b.fix_hint or "")


# --- contract text ----------------------------------------------------------------------------


def test_the_contract_states_the_new_rules_and_their_accepted_errors() -> None:
    for rid in NEW:
        assert f"| {rid} |" in CONTRACT
        assert f"**{rid}**" in CONTRACT, f"{rid} has no known-false-negatives entry"
    for pkg in ("DBMS_SQL", "UTL_FILE", "DBMS_LOB"):
        assert f"| `{pkg}` |" in CONTRACT
    assert "orientation, not a rewrite" in CONTRACT


# --- command ----------------------------------------------------------------------------------


def test_rules_filter_selects_only_the_new_rule() -> None:
    res = run(app, ["migrate", str(FIXTURES), "--format", "json", "--rules", "MIG012"])
    assert res.exit_code == 0
    rules = {f["rule_id"] for f in json.loads(res.output)["findings"]}
    assert rules == {"MIG012"}
    res = run(app, ["migrate", str(FIXTURES), "--format", "json", "--rules", "mig013, MIG017"])
    assert {f["rule_id"] for f in json.loads(res.output)["findings"]} == {"MIG013", "MIG017"}


def test_fail_on_uses_the_severity_of_each_mig016_finding() -> None:
    lob = str(FIXTURES / "MIG016" / "pos_3.pkb")  # only `medium` findings of MIG016
    sql = str(FIXTURES / "MIG016" / "pos_2.pkb")  # `high` findings
    base = ["migrate", "--rules", "MIG016"]
    assert run(app, [base[0], lob, *base[1:], "--fail-on", "high"]).exit_code == 0
    assert run(app, [base[0], lob, *base[1:], "--fail-on", "medium"]).exit_code == 1
    assert run(app, [base[0], sql, *base[1:], "--fail-on", "high"]).exit_code == 1


def test_sarif_lists_the_new_rules_with_per_finding_levels_and_validates() -> None:
    findings = [
        f
        for rid in NEW
        for p in sorted((FIXTURES / rid).glob("pos_*.pkb"))
        for f in migrate_file(p, [rid])
    ]
    doc = json.loads(to_sarif(findings))
    assert not list(Draft202012Validator(SCHEMA).iter_errors(doc))
    driver_rules = {r["id"]: r for r in doc["runs"][0]["tool"]["driver"]["rules"]}
    assert set(NEW) <= set(driver_rules)
    assert driver_rules["MIG016"]["defaultConfiguration"]["level"] == "error"
    assert driver_rules["MIG012"]["defaultConfiguration"]["level"] == "warning"
    levels = {r["ruleId"]: set() for r in doc["runs"][0]["results"]}
    for r in doc["runs"][0]["results"]:
        levels[r["ruleId"]].add(r["level"])
    assert levels["MIG016"] == {"warning", "error"}


def test_the_new_rules_report_counts_match_a_fresh_run_over_the_corpus() -> None:
    import collections
    import re

    from plsql_lens.inventory import collect_files

    occ: collections.Counter[tuple[str, str]] = collections.Counter()
    files: collections.defaultdict[tuple[str, str], set[str]] = collections.defaultdict(set)
    for path in collect_files([ROOT / "corpus"]):
        for f in migrate_file(path, NEW):
            occ[(f.rule_id, f.severity)] += 1
            files[(f.rule_id, f.severity)].add(f.location.path)
    text = (ROOT / "docs" / "reports" / "migrate-new-rules.md").read_text()
    rows = re.findall(r"^\| (MIG\d{3}) \| (\w+) \| (\d+) \| (\d+) \|$", text, flags=re.MULTILINE)
    reported = {(r, s): (int(o), int(n)) for r, s, o, n in rows}
    assert reported == {k: (occ[k], len(files[k])) for k in occ}
