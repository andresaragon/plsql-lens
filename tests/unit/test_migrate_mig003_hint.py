"""MIG003 fix hint (F5-G6, issue #3): written from docs/migration-rules.md, not from the code.

The hint tells the transaction clock from the real clock. It is one static text for every
finding: it must not depend on context, and it must not change the findings.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from plsql_lens.migrate import migrate_file, migrate_source

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "tests" / "fixtures" / "migrate" / "rules" / "MIG003"
CONTRACT = (ROOT / "docs" / "migration-rules.md").read_text()
WAIT_LOOP = (
    "DECLARE l_now TIMESTAMP := SYSTIMESTAMP;\n"
    "BEGIN\n"
    "  WHILE l_now < l_end LOOP\n"
    "    l_now := systimestamp;\n"
    "  END LOOP;\n"
    "END;\n"
)


@pytest.mark.parametrize("src", ["x := sysdate;", "x := systimestamp;", WAIT_LOOP])
def test_the_hint_names_clock_timestamp_and_keeps_the_transaction_functions(src: str) -> None:
    findings = migrate_source(src, "x.sql", ["MIG003"])
    assert findings
    for f in findings:
        hint = f.fix_hint or ""
        assert "clock_timestamp()" in hint
        for kept in ("CURRENT_TIMESTAMP", "LOCALTIMESTAMP", "CURRENT_DATE"):
            assert kept in hint


def test_the_hint_is_the_same_text_for_every_finding_whatever_the_context() -> None:
    texts = {
        f.fix_hint
        for src in ("x := sysdate;", "y := sysdate - 1;", WAIT_LOOP)
        for f in migrate_source(src, "x.sql", ["MIG003"])
    }
    assert len(texts) == 1


def test_the_rationale_and_message_text_did_not_change() -> None:
    (f,) = migrate_source("x := sysdate;", "x.sql", ["MIG003"])
    assert f.message == "Oracle SYSDATE"
    assert f.rationale.startswith("In Oracle SYSDATE is a DATE")


def test_the_wait_loop_fixture_flags_exactly_the_marked_reads_with_the_rule_severity() -> None:
    path = FIXTURES / "pos_4.pkb"
    findings = migrate_file(path, ["MIG003"])
    marked = {
        n for n, line in enumerate(path.read_text().splitlines(), 1) if "-- expect: MIG003" in line
    }
    assert marked and {f.location.line for f in findings} == marked
    assert {f.severity for f in findings} == {"medium"}
    assert all("clock_timestamp()" in (f.fix_hint or "") for f in findings)


def test_the_contract_explains_the_two_clocks_and_when_to_use_each() -> None:
    for text in ("clock_timestamp()", "start time of the current transaction", "busy-wait"):
        assert text in CONTRACT, text
