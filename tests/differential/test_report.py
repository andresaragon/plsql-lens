"""The counts in docs/reports/migrate-differential.md that do not need a database (F5-G1).

The number of generated, fully rewritable and skipped statements follows from the seed and from
``rewrite_sql``; if either changes, the report (and its CI run) is stale and must be redone.
"""

from __future__ import annotations

import re
from pathlib import Path

from fuzzgen import DEFAULT_N, DEFAULT_SEED, generate_statements

from plsql_lens.migrate.rewrite import rewrite_sql

REPORT = Path(__file__).resolve().parents[2] / "docs" / "reports" / "migrate-differential.md"


def _cell(label: str) -> int:
    m = re.search(rf"^\| {re.escape(label)} \| (\d+) \|$", REPORT.read_text(), flags=re.MULTILINE)
    assert m, f"the report has no row {label!r}"
    return int(m.group(1))


def test_the_report_states_the_seed_and_the_database_versions() -> None:
    text = REPORT.read_text()
    assert str(DEFAULT_SEED) in text
    assert "23.26.3" in text and "16.15" in text
    assert "ci-results/f5-differential" in text


def test_the_statement_counts_match_a_fresh_generation_and_rewrite() -> None:
    statements = generate_statements(DEFAULT_SEED, DEFAULT_N)
    skipped = sum(1 for s in statements if rewrite_sql(s.sql).skipped != ())
    assert _cell("Statements generated") == len(statements) == DEFAULT_N
    assert _cell("Skipped by the rewrite (not run)") == skipped
    assert _cell("Fully rewritable and executed") == len(statements) - skipped


def test_the_run_is_clean_and_the_control_was_detected() -> None:
    executed = _cell("Fully rewritable and executed")
    assert _cell("Same result on both databases") + _cell("Discrepancies") == executed
    assert _cell("Errors on Oracle") == 0 and _cell("Errors on PostgreSQL") == 0
    assert "detected" in REPORT.read_text().lower()
