"""Acceptance tests for the migration rules MIG001-MIG011 (F5a, docs/migration-rules.md).

Fixtures in tests/fixtures/migrate/rules/<RULE>/{pos,neg}_N.pkb were written from the contract, not
from the implementation. A trailing ``-- expect: MIGnnn`` marks the exact line of an expected
finding.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from plsql_lens.migrate import MIGRATION_RULES, migrate_file, migrate_source
from plsql_lens.rules import RULES, SEVERITIES, Finding

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "tests" / "fixtures" / "migrate" / "rules"
CONTRACT = ROOT / "docs" / "migration-rules.md"
RULE_IDS = [f"MIG{i:03d}" for i in range(1, 12)]
SEVERITY = {
    "MIG001": "low",
    "MIG002": "medium",  # the highest a finding can have; each finding carries its own
    "MIG003": "medium",
    "MIG004": "low",
    "MIG005": "medium",
    "MIG006": "medium",
    "MIG007": "medium",
    "MIG008": "high",
    "MIG009": "low",
    "MIG010": "low",
    "MIG011": "high",
}
EXPECT = re.compile(r"--\s*expect:\s*(MIG\d{3})(?:\s+(info|low|medium|high))?")
PER_FINDING = {"MIG002", "MIG011"}  # severity decided from the context of each match


def expected_lines(path: Path, rule: str) -> set[int]:
    return {
        n
        for n, line in enumerate(path.read_text().splitlines(), 1)
        if (m := EXPECT.search(line)) and m.group(1) == rule
    }


def expected_severities(path: Path, rule: str) -> dict[int, str]:
    """Line -> severity for the markers that state one (``-- expect: MIG011 info``)."""
    return {
        n: m.group(2)
        for n, line in enumerate(path.read_text().splitlines(), 1)
        if (m := EXPECT.search(line)) and m.group(1) == rule and m.group(2)
    }


def found(path: Path, rule: str) -> list[Finding]:
    return [f for f in migrate_file(path) if f.rule_id == rule]


# --- registry ---------------------------------------------------------------------------------


def test_the_registry_has_exactly_mig001_to_mig011_with_the_contract_severities() -> None:
    assert sorted(MIGRATION_RULES) == RULE_IDS
    assert {rid: r.severity for rid, r in MIGRATION_RULES.items()} == SEVERITY
    assert all(r.title.strip() and r.id == rid for rid, r in MIGRATION_RULES.items())


def test_migrate_does_not_register_anything_in_the_review_rules() -> None:
    assert sorted(RULES) == [f"PLL00{i}" for i in range(1, 8)]
    assert not set(RULES) & set(MIGRATION_RULES)


def test_the_contract_is_written_and_names_every_rule_and_its_false_negatives() -> None:
    text = CONTRACT.read_text()
    for rid in RULE_IDS:
        assert f"| {rid} |" in text, f"{rid} is missing from the contract table"
    assert "Known false negatives" in text
    assert "-- expect: MIGnnn" in text


# --- fixtures ---------------------------------------------------------------------------------


@pytest.mark.parametrize("rule", RULE_IDS)
def test_rule_has_three_positive_and_three_negative_fixtures(rule: str) -> None:
    assert len(list((FIXTURES / rule).glob("pos_*.pkb"))) >= 3
    assert len(list((FIXTURES / rule).glob("neg_*.pkb"))) >= 3
    for pos in (FIXTURES / rule).glob("pos_*.pkb"):
        assert expected_lines(pos, rule), f"{pos.name} has no expect marker"
    for neg in (FIXTURES / rule).glob("neg_*.pkb"):
        assert not expected_lines(neg, rule), f"{neg.name} must not expect {rule}"


CASES = [
    pytest.param(rule, path, id=f"{rule}/{path.name}")
    for rule in RULE_IDS
    for path in sorted((FIXTURES / rule).glob("*.pkb"))
]


@pytest.mark.parametrize(("rule", "path"), CASES)
def test_fixture_findings_match_markers(rule: str, path: Path) -> None:
    assert {f.location.line for f in found(path, rule)} == expected_lines(path, rule)


@pytest.mark.parametrize(("rule", "path"), CASES)
def test_one_finding_per_occurrence_with_the_contract_severity(rule: str, path: Path) -> None:
    stated = expected_severities(path, rule)
    for f in found(path, rule):
        assert f.location.path == str(path)
        assert f.location.col >= 1
        if rule in PER_FINDING:
            assert f.severity in SEVERITIES and SEVERITIES.index(f.severity) <= SEVERITIES.index(
                SEVERITY[rule]
            )
            if f.location.line in stated:
                assert f.severity == stated[f.location.line], (path.name, f.location.line)
        else:
            assert f.severity == SEVERITY[rule]


@pytest.mark.parametrize("rule", sorted(PER_FINDING))
def test_the_severity_markers_cover_every_level_the_rule_can_give(rule: str) -> None:
    levels = {
        sev
        for p in (FIXTURES / rule).glob("pos_*.pkb")
        for sev in expected_severities(p, rule).values()
    }
    assert levels == ({"info", "medium", "high"} if rule == "MIG011" else {"low", "medium"})


# --- finding text and details -----------------------------------------------------------------


@pytest.mark.parametrize("rule", RULE_IDS)
def test_every_finding_has_message_rationale_and_fix_hint(rule: str) -> None:
    findings = [f for p in sorted((FIXTURES / rule).glob("pos_*.pkb")) for f in found(p, rule)]
    assert findings
    for f in findings:
        assert f.message.strip() and f.rationale.strip() and (f.fix_hint or "").strip()


def test_mig002_message_says_so_when_a_search_argument_is_null() -> None:
    with_null = migrate_source("select decode(x, NULL, 'a', 'b') from t;", "x.sql", ["MIG002"])
    assert len(with_null) == 1 and "NULL" in with_null[0].message
    for src in (
        "select decode(x, 'k', 'a', 'b') from t;",
        "select decode(x, 'k', 'a', NULL) from t;",  # NULL as default is not a search argument
        "select decode(x, 'k', null, 'b') from t;",  # NULL as a result is not a search argument
    ):
        (f,) = migrate_source(src, "x.sql", ["MIG002"])
        assert "NULL" not in f.message, src


def test_mig002_null_in_a_later_search_position_is_found() -> None:
    (f,) = migrate_source("x := decode(a, 1, 'p', 2, 'q', NULL, 'r', 's');", "x.sql", ["MIG002"])
    assert "NULL" in f.message


def test_mig002_nested_commas_do_not_shift_the_argument_positions() -> None:
    (f,) = migrate_source("x := decode(f(a, NULL), 'k', 1, 0);", "x.sql", ["MIG002"])
    assert "NULL" not in f.message


@pytest.mark.parametrize(
    ("src", "rule", "col"),
    [
        ("x := nvl(a, b);", "MIG001", 6),
        ("  y := sys.dbms_output.put_line('q');", "MIG009", 8),  # the sys token
        ("select 1 from dual;", "MIG010", 15),
        ("a := seq.nextval;", "MIG004", 10),
        ("where a = b(+)", "MIG007", 12),
    ],
)
def test_locations_point_at_the_token_named_in_the_contract(src: str, rule: str, col: int) -> None:
    (f,) = migrate_source(src, "x.sql", [rule])
    assert (f.location.line, f.location.col) == (1, col)


def test_mig003_matches_both_names_and_nothing_inside_strings_or_comments() -> None:
    src = "a := sysdate; b := systimestamp; c := 'sysdate'; -- sysdate\n/* systimestamp */"
    assert [f.location.col for f in migrate_source(src, "x.sql", ["MIG003"])] == [6, 20]


def test_mig011_flags_the_empty_string_and_the_national_empty_string_only() -> None:
    src = "a := ''; b := n''; c := ' '; d := ''''; e := 'x'; f := q'[]';"
    assert [f.location.col for f in migrate_source(src, "x.sql", ["MIG011"])] == [6, 15]


def test_mig009_requires_a_call() -> None:
    assert not migrate_source("grant execute on dbms_output to u;", "x.sql", ["MIG009"])
    assert len(migrate_source("dbms_output.new_line;", "x.sql", ["MIG009"])) == 1


def test_mig006_needs_connect_immediately_followed_by_by() -> None:
    assert len(migrate_source("select 1 from d connect\n by level < 3;", "x.sql", ["MIG006"])) == 1
    assert not migrate_source("grant connect to u by x;", "x.sql", ["MIG006"])


def test_declarations_outside_statement_bodies_are_covered() -> None:
    src = "CREATE PACKAGE BODY p AS\n  g DATE := SYSDATE;\n  PRAGMA SERIALLY_REUSABLE;\nEND p;\n/\n"
    (f,) = migrate_source(src, "p.pkb", ["MIG003"])
    assert f.location.line == 2


# --- the API ----------------------------------------------------------------------------------


def test_migrate_source_and_migrate_file_agree() -> None:
    path = FIXTURES / "MIG001" / "pos_2.pkb"
    assert migrate_source(path.read_text(), str(path)) == migrate_file(path)


def test_rules_argument_restricts_the_rules_and_unknown_ids_are_an_error() -> None:
    path = FIXTURES / "MIG010" / "pos_1.pkb"
    assert {f.rule_id for f in migrate_file(path, ["MIG010"])} == {"MIG010"}
    assert migrate_file(path, ["MIG001"]) == []
    with pytest.raises(ValueError, match="MIG999"):
        migrate_file(path, ["MIG999"])


def test_findings_are_sorted_by_line_column_and_rule_id() -> None:
    src = "x := sysdate; y := nvl(a, '');\nz := decode(a, 1, 2) from dual;\n"
    keys = [(f.location.line, f.location.col, f.rule_id) for f in migrate_source(src, "x.sql")]
    assert keys == sorted(keys) and len(keys) >= 5


def test_the_enclosing_unit_is_filled_from_the_ir_by_line_range() -> None:
    src = (
        "CREATE OR REPLACE PACKAGE BODY pkg_u AS\n"
        "  PROCEDURE a IS\n"
        "  BEGIN\n"
        "    x := SYSDATE;\n"
        "  END a;\n"
        "  PROCEDURE b IS\n"
        "  BEGIN\n"
        "    y := SYSDATE;\n"
        "  END b;\n"
        "END pkg_u;\n/\n"
    )
    assert [f.unit for f in migrate_source(src, "p.pkb", ["MIG003"])] == ["pkg_u.a", "pkg_u.b"]


def test_a_file_with_no_oracle_constructs_has_no_findings_and_junk_does_not_raise() -> None:
    assert migrate_source("", "empty.sql") == []
    assert migrate_source("select 1;\n", "plain.sql") == []
    assert isinstance(migrate_source("'unterminated /* (+ nvl( decode(", "junk.sql"), list)


# --- suppression ------------------------------------------------------------------------------


def test_inline_suppression_works_for_migration_rule_ids() -> None:
    src = (
        "CREATE OR REPLACE PACKAGE BODY pkg_s AS\n"
        "  PROCEDURE a IS\n"
        "  BEGIN\n"
        "    x := nvl(p, 0); -- plsql-lens: disable=MIG001\n"
        "    -- plsql-lens: disable=MIG001\n"
        "    y := nvl(p, 1);\n"
        "    z := nvl(p, 2);\n"
        "  END a;\n"
        "END pkg_s;\n/\n"
    )
    assert [f.location.line for f in migrate_source(src, "p.pkb", ["MIG001"])] == [7]


def test_suppressing_one_rule_keeps_the_others() -> None:
    src = "BEGIN x := nvl(sysdate, d); -- plsql-lens: disable=MIG001\nEND;\n"
    assert {f.rule_id for f in migrate_source(src, "p.sql")} == {"MIG003"}


def test_a_header_line_directive_suppresses_the_whole_subprogram() -> None:
    src = (
        "CREATE OR REPLACE PACKAGE BODY pkg_h AS\n"
        "  PROCEDURE a IS -- plsql-lens: disable=MIG003\n"
        "  BEGIN\n"
        "    x := SYSDATE;\n"
        "    y := nvl(SYSTIMESTAMP, d);\n"
        "  END a;\n"
        "END pkg_h;\n/\n"
    )
    assert {f.rule_id for f in migrate_source(src, "p.pkb")} == {"MIG001"}
