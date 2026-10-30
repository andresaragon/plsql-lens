"""The counts in docs/reports/phase-5a.md are what ``plsql-lens migrate corpus`` prints."""

from __future__ import annotations

import collections
import re
from pathlib import Path

from plsql_lens.inventory import collect_files
from plsql_lens.migrate import MIGRATION_RULES, migrate_file

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs" / "reports" / "phase-5a.md"
ROW = re.compile(r"^\| (MIG\d{3}) \| (\w+) \| (\d+) \| (\d+) \|$", re.MULTILINE)


def test_report_counts_match_a_fresh_run_over_the_corpus() -> None:
    occurrences: collections.Counter[str] = collections.Counter()
    files: collections.defaultdict[str, set[str]] = collections.defaultdict(set)
    for path in collect_files([ROOT / "corpus"]):
        for f in migrate_file(path):
            occurrences[f.rule_id] += 1
            files[f.rule_id].add(f.location.path)
    reported = {m[1]: (m[2], int(m[3]), int(m[4])) for m in ROW.finditer(REPORT.read_text())}
    assert sorted(reported) == sorted(MIGRATION_RULES)
    for rid, (severity, occ, nfiles) in reported.items():
        assert severity == MIGRATION_RULES[rid].severity
        assert (occ, nfiles) == (occurrences[rid], len(files[rid])), rid
