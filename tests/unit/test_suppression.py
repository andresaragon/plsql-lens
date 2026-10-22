from __future__ import annotations

from plsql_lens.parser import parse_source
from plsql_lens.rules import review

SRC = """\
CREATE OR REPLACE PROCEDURE p IS
  l_n NUMBER;
BEGIN
  FOR r IN (SELECT 1 FROM dual) LOOP
    COMMIT;{trailing}
    -- plsql-lens: disable=PLL003
    COMMIT;
    COMMIT;
  END LOOP;
END p;
"""


def lines(src: str, rule: str = "PLL003") -> list[int]:
    return [f.location.line for f in review(parse_source(src, "x.sql")) if f.rule_id == rule]


def test_trailing_directive_suppresses_its_own_line() -> None:
    assert lines(SRC.format(trailing="")) == [5, 8]
    assert lines(SRC.format(trailing=" -- plsql-lens: disable=PLL003")) == [8]


def test_own_line_directive_applies_to_next_code_line_only() -> None:
    assert 7 not in lines(SRC.format(trailing=""))
    assert 8 in lines(SRC.format(trailing=""))


def test_directive_lists_several_rules_and_ignores_others() -> None:
    src = SRC.format(trailing=" -- plsql-lens: disable=PLL001, PLL003")
    assert 5 not in lines(src)
    src = SRC.format(trailing=" -- plsql-lens: disable=PLL001")
    assert 5 in lines(src)


def test_directive_on_subprogram_header_suppresses_whole_body() -> None:
    src = "-- plsql-lens: disable=PLL003\n" + SRC.format(trailing="")
    assert lines(src) == []
    src = SRC.format(trailing="").replace(
        "PROCEDURE p IS", "PROCEDURE p IS -- plsql-lens: disable=PLL003"
    )
    assert lines(src) == []


def test_review_can_ignore_suppressions() -> None:
    from plsql_lens.rules import review as run

    ir = parse_source(SRC.format(trailing=" -- plsql-lens: disable=PLL003"), "x.sql")
    assert 5 in [f.location.line for f in run(ir, suppress=False) if f.rule_id == "PLL003"]
