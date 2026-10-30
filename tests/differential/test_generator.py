"""Unit tests (no database, no network) for the differential-fuzzing generator (F5-G1).

The generator emits integer-only ``SELECT <expr> FROM (SELECT ... FROM DUAL)`` statements with
``NVL`` and ``DECODE``; each one must go through ``rewrite_sql`` without raising, idempotently, and
without leaving an ``NVL(`` or ``DECODE(`` behind unless the rewrite said it skipped something.
"""

from __future__ import annotations

import collections
import re

import pytest
from fuzzgen import (
    BASE,
    COLUMNS,
    DEFAULT_N,
    DEFAULT_SEED,
    Statement,
    generate_statements,
    max_call_depth,
)

from plsql_lens.migrate.rewrite import rewrite_sql
from plsql_lens.parser.lexer import IDENT, NUMBER, OP, STRING, tokenize

N = 2000
STATEMENTS = generate_statements(DEFAULT_SEED, N)
ALLOWED_WORDS = {
    "select",
    "from",
    "cast",
    "null",
    "as",
    "integer",
    "nvl",
    "decode",
    "dual",
    *COLUMNS,
}


def test_the_defaults_are_a_fixed_seed_and_2000_statements() -> None:
    assert DEFAULT_N == 2000 and isinstance(DEFAULT_SEED, int)


def test_the_generator_is_deterministic_for_a_seed() -> None:
    a = generate_statements(DEFAULT_SEED, 300)
    assert a == generate_statements(DEFAULT_SEED, 300)
    assert a != generate_statements(DEFAULT_SEED + 1, 300)
    assert [s.sql for s in generate_statements(DEFAULT_SEED, 100)] == [s.sql for s in a[:100]]


def test_at_least_2000_distinct_statements_with_unique_ids() -> None:
    assert len(STATEMENTS) >= 2000
    assert len({s.id for s in STATEMENTS}) == len(STATEMENTS)
    assert len({s.sql for s in STATEMENTS}) == len(STATEMENTS)
    assert all(isinstance(s, Statement) for s in STATEMENTS)


def test_every_statement_has_the_fixed_shape() -> None:
    head, tail = BASE.split("{expr}")
    assert tail == (
        " FROM (SELECT CAST(NULL AS INTEGER) n1, CAST(NULL AS INTEGER) n2, "
        "1 v1, 2 v2, 2 v3, 7 v4 FROM DUAL)"
    )
    for s in STATEMENTS:
        assert s.sql.startswith(head) and s.sql.endswith(tail), s.sql


def test_the_generator_stays_integer_only_and_avoids_the_known_divergences() -> None:
    for s in STATEMENTS:
        assert "'" not in s.sql and "||" not in s.sql and '"' not in s.sql, s.sql
        for t in tokenize(s.sql):
            assert t.kind != STRING, s.sql
            if t.kind == IDENT:
                assert t.text in ALLOWED_WORDS, (t.text, s.sql)
            elif t.kind == NUMBER:
                assert re.fullmatch(r"\d", t.text) or t.text in {"1", "2", "7"}, s.sql
            else:
                assert t.kind == OP and t.text in "(),+", (t.text, s.sql)


def _enclosing_call(tokens: list, i: int) -> tuple[str, int]:  # type: ignore[type-arg]
    """Name of the call that encloses token ``i`` and the index of the argument it is in."""
    depth, arg = 0, 0
    for k in range(i - 1, -1, -1):
        t = tokens[k]
        if t.kind == OP and t.text == ")":
            depth += 1
        elif t.kind == OP and t.text == "(":
            if depth == 0:
                return tokens[k - 1].text, arg
            depth -= 1
        elif t.kind == OP and t.text == "," and depth == 0:
            arg += 1
    raise AssertionError("no enclosing call")


def test_a_bare_null_only_appears_as_a_decode_search_value() -> None:
    seen = 0
    for s in STATEMENTS:
        toks = tokenize(s.sql)
        for i, t in enumerate(toks):
            if t.kind != IDENT or t.text != "null":
                continue
            if toks[i - 1].text == "(" and toks[i - 2].text == "cast":
                continue  # CAST(NULL AS INTEGER), the typed NULL
            seen += 1
            call, arg = _enclosing_call(toks, i)
            assert call == "decode" and arg >= 1 and arg % 2 == 1, s.sql
    assert seen > 100, "the fuzzer should exercise NULL as a search value"


def test_calls_nest_at_most_three_deep_and_all_three_depths_occur() -> None:
    depths = collections.Counter(max_call_depth(s.sql) for s in STATEMENTS)
    assert max(depths) <= 3
    assert {1, 2, 3} <= set(depths)


def test_both_functions_and_the_plus_one_form_are_generated() -> None:
    text = "\n".join(s.sql for s in STATEMENTS)
    assert "NVL(" in text and "DECODE(" in text and " + 1" in text
    assert sum("DECODE(" in s.sql for s in STATEMENTS) > 500
    assert sum("NVL(" in s.sql for s in STATEMENTS) > 500


def test_every_statement_rewrites_without_raising_and_idempotently() -> None:
    for s in STATEMENTS:
        r = rewrite_sql(s.sql)
        again = rewrite_sql(r.sql)
        assert again.sql == r.sql, s.sql


def test_a_fully_rewritten_statement_has_no_nvl_or_decode_call_left() -> None:
    calls = re.compile(r"\b(nvl|decode)\s*\(", re.I)
    full = 0
    for s in STATEMENTS:
        r = rewrite_sql(s.sql)
        if r.skipped == ():
            full += 1
            assert not calls.search(r.sql), (s.sql, r.sql)
            assert "DUAL" not in r.sql.upper(), r.sql
    assert full > 0


def test_the_share_of_fully_rewritable_statements_is_reported(
    capsys: pytest.CaptureFixture[str],
) -> None:
    skipped: collections.Counter[str] = collections.Counter()
    full = 0
    for s in STATEMENTS:
        r = rewrite_sql(s.sql)
        if r.skipped == ():
            full += 1
        for _, reason in r.skipped:
            skipped[reason] += 1
    pct = 100 * full / len(STATEMENTS)
    with capsys.disabled():
        print(
            f"\nfully rewritable: {full}/{len(STATEMENTS)} = {pct:.1f}%"
            f"  skipped by reason: {dict(skipped)}"
        )
    # The fuzzer is only useful if a good share reaches the databases; the skips (a NULL-able search
    # value over a non-simple subject) are intended, not a defect.
    assert pct >= 30
