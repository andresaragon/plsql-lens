"""Acceptance tests for ``rewrite_sql`` (F5b): conservative, idempotent, byte-preserving rewrites.

The 37 reference cases of tests/fixtures/migrate/semantics.json (results observed on Oracle) drive
the unit checks; the integration test runs the same rewrites on PostgreSQL.
"""

from __future__ import annotations

import dataclasses
import json
import re
from pathlib import Path

import pytest

from plsql_lens.migrate.rewrite import Rewrite, rewrite_sql

ROOT = Path(__file__).resolve().parents[2]
SEMANTICS = ROOT / "tests" / "fixtures" / "migrate" / "semantics.json"
CASES = json.loads(SEMANTICS.read_text())["cases"]
IDS = [c["id"] for c in CASES]

# What each reference case contains, found independently of the implementation, in source order.
PATTERNS = [
    ("MIG001", re.compile(r"\bnvl\s*\(", re.I)),
    ("MIG002", re.compile(r"\bdecode\s*\(", re.I)),
    ("MIG004", re.compile(r"\.\s*(?:nextval|currval)\b", re.I)),
    ("MIG010", re.compile(r"\bfrom\s+dual\b", re.I)),
]


def expected_applied(sql: str) -> list[str]:
    hits = [(m.start(), rid) for rid, rx in PATTERNS for m in rx.finditer(sql)]
    return [rid for _, rid in sorted(hits)]


def rw(sql: str) -> Rewrite:
    return rewrite_sql(sql)


# --- the result type --------------------------------------------------------------------------


def test_rewrite_is_a_frozen_slots_dataclass_with_the_three_fields() -> None:
    r = rw("select 1 from dual")
    assert [f.name for f in dataclasses.fields(Rewrite)] == ["sql", "applied", "skipped"]
    assert isinstance(r.applied, tuple) and isinstance(r.skipped, tuple)
    with pytest.raises(dataclasses.FrozenInstanceError):
        r.sql = "x"  # type: ignore[misc]
    assert not hasattr(r, "__dict__")


def test_nothing_to_rewrite_returns_the_input_unchanged() -> None:
    for sql in ("", "select 1", "select a, b from t where x = 1;\n", "-- only a comment"):
        r = rw(sql)
        assert (r.sql, r.applied, r.skipped) == (sql, (), ())


# --- the 37 reference cases -------------------------------------------------------------------


@pytest.mark.parametrize("case", CASES, ids=IDS)
def test_reference_case_is_rewritten_with_the_expected_rules(case: dict[str, object]) -> None:
    sql = str(case["oracle_sql"])
    r = rw(sql)
    assert list(r.applied) == expected_applied(sql)
    assert r.skipped == ()
    assert r.sql != sql
    for _, rx in PATTERNS:
        assert not rx.search(r.sql), f"{rx.pattern} survived in {r.sql!r}"


@pytest.mark.parametrize("case", CASES, ids=IDS)
def test_reference_case_rewrite_is_idempotent(case: dict[str, object]) -> None:
    once = rw(str(case["oracle_sql"]))
    twice = rw(once.sql)
    assert twice.sql == once.sql
    assert twice.applied == ()


@pytest.mark.parametrize("case", CASES, ids=IDS)
def test_text_around_the_rewritten_spans_is_untouched_byte_for_byte(
    case: dict[str, object],
) -> None:
    sql = str(case["oracle_sql"])
    head = "/* lead nvl(1,2) */ \t\r\n-- from dual\n  "
    tail = "\r\n  -- tail decode(1,2,3) ' \" /*\n"
    inner = rw(sql).sql
    assert rw(head + sql + tail).sql == head + inner + tail


@pytest.mark.parametrize("case", CASES, ids=IDS)
def test_every_prefix_of_a_reference_case_is_idempotent_and_never_raises(
    case: dict[str, object],
) -> None:
    sql = str(case["oracle_sql"])
    for n in range(len(sql) + 1):
        once = rw(sql[:n])
        assert rw(once.sql).sql == once.sql, sql[:n]


def test_the_semantics_file_is_read_only_data_with_37_cases_and_5_divergences() -> None:
    assert len(CASES) == 37
    assert sum("known_divergence" in c for c in CASES) == 5


# --- exact output of each rewrite -------------------------------------------------------------


@pytest.mark.parametrize(
    ("sql", "expected"),
    [
        ("select nvl(a, b) from t", "select coalesce(a, b) from t"),
        ("select NVL(a, b) from t", "select COALESCE(a, b) from t"),
        ("select Nvl(a, b) from t", "select COALESCE(a, b) from t"),
        ("select nvl (a ,\n   b ) from t", "select coalesce (a ,\n   b ) from t"),
        ("x := NVL(NVL(a,b),c);", "x := COALESCE(COALESCE(a,b),c);"),
        ("x := nvl(f(1, 2), g(3));", "x := coalesce(f(1, 2), g(3));"),
        ("select nvl(a /* why */, 0) from t", "select coalesce(a /* why */, 0) from t"),
    ],
)
def test_nvl_becomes_coalesce_keeping_everything_else(sql: str, expected: str) -> None:
    r = rw(sql)
    assert r.sql == expected and set(r.applied) == {"MIG001"} and r.skipped == ()


@pytest.mark.parametrize(
    ("sql", "expected"),
    [
        ("DECODE(x, 'Y', 1, 0)", "CASE x WHEN 'Y' THEN 1 ELSE 0 END"),
        ("DECODE(x, 1, 'a', 2, 'b')", "CASE x WHEN 1 THEN 'a' WHEN 2 THEN 'b' END"),
        (
            "DECODE(x, 1, 'a', 2, 'b', 'c')",
            "CASE x WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END",
        ),
        ("Decode(f(x), 1, 'a', 'z')", "CASE f(x) WHEN 1 THEN 'a' ELSE 'z' END"),
    ],
)
def test_decode_becomes_a_case_expression(sql: str, expected: str) -> None:
    r = rw(sql)
    assert r.sql == expected, r
    assert r.applied == ("MIG002",) and r.skipped == ()


def test_decode_keywords_follow_the_case_of_the_decode_keyword() -> None:
    assert rw("decode(x, 1, 'a', 'b')").sql == "case x when 1 then 'a' else 'b' end"


def test_decode_with_a_null_search_value_matches_null_with_null() -> None:
    r = rw("DECODE(x, NULL, 'none', 'k', 'key', 'other')")
    assert r.sql == "CASE WHEN x IS NULL THEN 'none' WHEN x = 'k' THEN 'key' ELSE 'other' END"
    assert r.applied == ("MIG002",)


def test_decode_with_a_null_search_value_wraps_compound_operands() -> None:
    r = rw("DECODE(a + b, NULL, 0, c || d, 1)")
    assert r.sql == "CASE WHEN (a + b) IS NULL THEN 0 WHEN (a + b) = (c || d) THEN 1 END"


def test_decode_with_a_literal_null_subject_uses_the_when_form() -> None:
    # On PostgreSQL an untyped NULL after CASE is text, so `CASE NULL WHEN 1` is an error
    # (found by running reference case decode_06 on PostgreSQL 16).
    r = rw("DECODE(NULL, 1, 'a', 'z')")
    assert r.sql == "CASE WHEN NULL = 1 THEN 'a' ELSE 'z' END"
    r = rw("DECODE(NULL, 1, 'a', NULL, 'n', 'd')")
    assert r.sql == "CASE WHEN NULL = 1 THEN 'a' WHEN NULL IS NULL THEN 'n' ELSE 'd' END"


def test_decode_null_as_result_or_default_needs_no_special_form() -> None:
    assert rw("DECODE(x, 1, NULL, 2)").sql == "CASE x WHEN 1 THEN NULL ELSE 2 END"
    assert rw("DECODE(x, 1, 'a', NULL)").sql == "CASE x WHEN 1 THEN 'a' ELSE NULL END"


def test_decode_with_a_null_search_and_a_non_simple_expression_is_skipped() -> None:
    # The NULL-safe form would evaluate the expression more than once.
    for e in ("f(x)", "seq.nextval", "(select max(a) from t)"):
        sql = f"decode({e}, null, 1, 2)"
        r = rw(sql)
        assert r.sql.startswith("decode(") and "MIG002" not in r.applied, e
        assert r.skipped[0][0] == "MIG002" and "NULL" in r.skipped[0][1], e


def test_nested_decode_and_nvl_inside_decode_are_rewritten_inside_out() -> None:
    r = rw("DECODE(DECODE(1, 1, 2, 3), 2, NVL(a, 'x'), 'no')")
    assert (
        r.sql == "CASE CASE 1 WHEN 1 THEN 2 ELSE 3 END WHEN 2 THEN COALESCE(a, 'x') ELSE 'no' END"
    )
    assert r.applied == ("MIG002", "MIG002", "MIG001")


def test_decode_multiline_arguments_keep_their_own_text() -> None:
    r = rw("DECODE(a,\n  'x',\n  'long result',\n  'z')")
    assert r.sql == "CASE a WHEN 'x' THEN 'long result' ELSE 'z' END"


@pytest.mark.parametrize(
    ("sql", "expected"),
    [
        ("select seq.nextval from t", "select nextval('seq') from t"),
        ("x := seq.NEXTVAL;", "x := nextval('seq');"),
        ("x := sch.seq.CURRVAL;", "x := currval('sch.seq');"),
        ("x := a . b . nextval;", "x := nextval('a.b');"),
        ('x := "My Seq".nextval;', "x := nextval('\"My Seq\"');"),
        ("x := F5_S6.nextval + 1;", "x := nextval('F5_S6') + 1;"),
        ("x := s.nextval + s.currval;", "x := nextval('s') + currval('s');"),
    ],
)
def test_sequence_pseudo_columns_become_function_calls(sql: str, expected: str) -> None:
    r = rw(sql)
    assert r.sql == expected and set(r.applied) == {"MIG004"} and r.skipped == ()


@pytest.mark.parametrize(
    ("sql", "expected"),
    [
        ("select 1 from dual", "select 1"),
        ("SELECT 1 FROM DUAL;", "SELECT 1;"),
        ("select   2 * 3 FROM   DUAL", "select   2 * 3"),
        ("select 'x' from dual where 1 = 1", "select 'x' where 1 = 1"),
        ("select 1\n  from dual\n order by 1", "select 1\n order by 1"),
        ("select (select 1 from dual) from t", "select (select 1) from t"),
        ("select 1 from dual union all select 2 from dual", "select 1 union all select 2"),
        ("insert into t select 1 from dual", "insert into t select 1"),
    ],
)
def test_from_dual_is_dropped(sql: str, expected: str) -> None:
    r = rw(sql)
    assert r.sql == expected and set(r.applied) == {"MIG010"} and r.skipped == ()


@pytest.mark.parametrize(
    "sql",
    [
        "select * from dual",
        "select t.* from dual",
        "delete from dual",
        "select 1 from dual d",
        "select 1 from dual, t",
        "select 1 from dual join t on 1 = 1",
        "select 1 from dual connect by level < 3",
    ],
)
def test_from_dual_is_skipped_when_dropping_it_would_change_the_meaning(sql: str) -> None:
    r = rw(sql)
    assert r.sql == sql and r.applied == () and [s[0] for s in r.skipped] == ["MIG010"]


def test_mixed_constructs_are_applied_in_source_order() -> None:
    r = rw("select nvl(seq.nextval, 0), decode(x, 1, 'a') from dual")
    assert r.sql == "select coalesce(nextval('seq'), 0), case x when 1 then 'a' end"
    assert r.applied == ("MIG001", "MIG004", "MIG002", "MIG010")


# --- conservative: never half a rewrite -------------------------------------------------------


@pytest.mark.parametrize(
    ("sql", "rule"),
    [
        ("select nvl(a, b from t", "MIG001"),
        ("select decode(a, 1, 2 from t", "MIG002"),
        ("select (nvl(a, b) from t", None),  # an unrelated unbalanced paren does not stop NVL
    ],
)
def test_unbalanced_parentheses_leave_the_construct_alone(sql: str, rule: str | None) -> None:
    r = rw(sql)
    if rule:
        assert r.sql == sql and r.applied == ()
        assert r.skipped and r.skipped[0][0] == rule and "parenthes" in r.skipped[0][1]
    else:
        assert r.sql == "select (coalesce(a, b) from t"


@pytest.mark.parametrize(
    ("sql", "rule"),
    [
        ("decode(a, /* note */ 1, 'x', 'y')", "MIG002"),
        ("decode(a, 1, 'x', -- note\n 'y')", "MIG002"),
        ("x := seq /* note */ .nextval;", "MIG004"),
        ("x := seq. -- note\n nextval;", "MIG004"),
        ("select 1 /* note */ from dual", "MIG010"),
        ("select 1 from -- note\n dual", "MIG010"),
    ],
)
def test_a_comment_inside_the_construct_leaves_it_alone(sql: str, rule: str) -> None:
    r = rw(sql)
    assert r.sql == sql and r.applied == ()
    assert [s[0] for s in r.skipped] == [rule] and "comment" in r.skipped[0][1]


@pytest.mark.parametrize(
    ("sql", "rule"),
    [
        ("nvl(a)", "MIG001"),
        ("nvl(a, b, c)", "MIG001"),
        ("nvl()", "MIG001"),
        ("decode(a)", "MIG002"),
        ("decode(a, 1)", "MIG002"),
        ("decode()", "MIG002"),
        ("decode(a, , 1)", "MIG002"),
    ],
)
def test_impossible_arity_leaves_the_construct_alone(sql: str, rule: str) -> None:
    r = rw(sql)
    assert r.sql == sql and r.applied == ()
    assert [s[0] for s in r.skipped] == [rule]


def test_a_remote_sequence_is_not_rewritten() -> None:
    r = rw("x := seq.nextval@remote_db;")
    assert r.sql == "x := seq.nextval@remote_db;" and r.skipped[0][0] == "MIG004"


def test_a_skipped_outer_construct_does_not_stop_its_inner_ones() -> None:
    r = rw("decode(a, /* c */ 1, nvl(x, y), 2)")
    assert r.sql == "decode(a, /* c */ 1, coalesce(x, y), 2)"
    assert r.applied == ("MIG001",) and [s[0] for s in r.skipped] == ["MIG002"]


# --- things that are not the constructs --------------------------------------------------------


@pytest.mark.parametrize(
    "sql",
    [
        "x := nvl2(a, b, c);",
        "x := pkg.nvl(a, b);",
        "x := pkg.decode(a, 1, 2);",
        "x := nvl;",
        "x := 'nvl(a, b) decode(a, 1, 2) seq.nextval from dual';",
        "x := 1; -- nvl(a, b) from dual seq.nextval decode(a, 1, 2)",
        "x := 1; /* nvl(a, b)\n from dual */",
        "select 1 from my_dual",
        "select 1 from sys.dual",
        "x := nextval('seq');",
        "x := my_nextval + currval_total;",
        "x := q'[nvl(a, b)]';",
    ],
)
def test_text_that_only_looks_like_a_construct_is_left_alone(sql: str) -> None:
    r = rw(sql)
    assert (r.sql, r.applied, r.skipped) == (sql, (), ())


JUNK = [
    "(",
    ")",
    "nvl(",
    "decode(",
    "'unterminated nvl(a,b)",
    "/* nvl(a,b)",
    "\x00",
    "from dual from dual",
    "nvl(nvl(nvl(",
    ".nextval",
    "a..nextval",
    '"nvl"(a, b)',
]


@pytest.mark.parametrize("junk", JUNK)
def test_junk_input_never_raises_and_stays_idempotent(junk: str) -> None:
    r = rw(junk)
    assert rw(r.sql).sql == r.sql


# --- independence from the detection rules and the CLI ----------------------------------------


def test_rewrite_module_does_not_import_the_rules_or_the_cli() -> None:
    src = (ROOT / "src" / "plsql_lens" / "migrate" / "rewrite.py").read_text()
    assert "MIGRATION_RULES" not in src
    assert not re.search(
        r"^\s*(from|import)\s+[.\w]*(cli|migrate\.rules|migrate import)\b", src, re.M
    )
    assert "tokenize" in src
