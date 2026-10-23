"""F4 tuning: false positives found in F2 (QC sample) and on the dev split."""

from __future__ import annotations

from plsql_lens.parser import parse_source
from plsql_lens.rules import review


def lines(src: str, rule: str) -> list[int]:
    return [f.location.line for f in review(parse_source(src, "x.sql")) if f.rule_id == rule]


def sel(select_list: str, tail: str = "from t where k = 1") -> str:
    return (
        "create or replace procedure p is\n  v number;\nbegin\n"
        f"  select {select_list} into v {tail};\nend p;\n"
    )


def test_pll004_aggregate_nested_in_an_expression_is_one_row() -> None:
    assert lines(sel("nvl(max(line_item_id), 0) + 1"), "PLL004") == []
    assert lines(sel("round(avg(x), 2)"), "PLL004") == []
    assert lines(sel("listagg(name, ',') within group (order by name)"), "PLL004") == []


def test_pll004_still_flags_what_can_return_zero_or_many_rows() -> None:
    assert lines(sel("max(x)", "from t group by k"), "PLL004") == [4]
    assert lines(sel("count(*)", "from t having count(*) > 5"), "PLL004") == [4]
    assert lines(sel("max(x) over (partition by k)"), "PLL004") == [4]
    assert lines(sel("x"), "PLL004") == [4]
    assert lines(sel("(select max(y) from u)", "from t"), "PLL004") == [4]
    assert lines(sel("xmlagg(xmlelement(e, x))", "from t having count(*) > 0"), "PLL004") == [4]


def cmp(expr: str) -> str:
    return (
        "create or replace procedure p(p_a date, p_b date) is\n  l_s date := p_a;\n"
        f"  l_e date := p_b;\n  l_t varchar2(10);\nbegin\n  if {expr} then null; end if;\nend p;\n"
    )


def test_pll006_operands_next_to_arithmetic_are_not_simple() -> None:
    assert lines(cmp("l_e - l_s < 3"), "PLL006") == []
    assert lines(cmp("3 > l_e - l_s"), "PLL006") == []
    assert lines(cmp("l_e = l_s + 1"), "PLL006") == []
    assert lines(cmp("l_t || 'x' = 5"), "PLL006") == []


def test_pll006_plain_mismatch_is_still_flagged() -> None:
    assert lines(cmp("l_t = 5"), "PLL006") == [6]
    assert lines(cmp("l_s = '2020-01-01'"), "PLL006") == [6]


def lit(expr: str) -> list[int]:
    src = (
        "create or replace procedure p is\n  v varchar2(10);\nbegin\n"
        f"  v := {expr};\n  v := {expr};\n  v := {expr};\nend p;\n"
    )
    return lines(src, "PLL007")


def test_pll007_escaped_quote_is_a_single_non_alphanumeric_character() -> None:
    assert lit("''''") == []  # the value is one quote
    assert lit("q'[']'") == []
    assert lit("'ab'") == [4, 5, 6]
    assert lit("''''''") == [4, 5, 6]  # two quotes are not exempt
