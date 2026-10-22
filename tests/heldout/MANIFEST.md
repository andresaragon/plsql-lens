# Held-out set (sealed reserve)

Files (labels in `labels.json`, keyed by repo-relative path):
- `corpus/utplsql/core/ut_suite_builder.pkb`
- `corpus/utplsql/core/ut_suite_cache_manager.pkb`
- `corpus/utplsql/reporters/ut_realtime_reporter.tpb`

Labeled by hand, by reading the code against `docs/rules.md` (PLL001-PLL007), before the rules were
implemented. Rule output on these files must NOT be used to tune rules; they are only for the
final measurement (F4).

## Judgment calls
- `ut_realtime_reporter.tpb` is a TYPE body; the contract lists package body/subprogram/trigger as PLL007 units. Treated the whole type body as one unit. If the tool does not treat type bodies as units, all 106 PLL007 labels there become false negatives by design.
- One PLL007 label per occurrence; two occurrences on one line (`chr(10)||chr(10)`, lines 105/143/145/187/201) appear as duplicate entries.
- SQL hints (`/*+ ... 500 */`) treated as comments, not literals. Package-level cursor in the cache manager treated as a declaration (not scanned); neither changes any label.
- `'</'` (2 chars) and `'.%'` count as literals (only SINGLE non-alphanumeric chars are exempt); `'.%'` occurs only twice, so unlabeled.
- PLL004 exempt cases in the cache manager: `SELECT MIN(..) INTO`, `SELECT COUNT(1) INTO .. FROM DUAL`, and `BULK COLLECT INTO`. `COMMIT`s there are outside any loop (PLL003 none).
- `to_char(x, fmt)` and `to_char(x)` are not PLL006(a) (only TO_DATE/TO_TIMESTAMP).

## Addendum: two more sealed files (same method; labeled by reading only)
- Added `corpus/utplsql/core/annotations/ut_annotation_manager.pkb` (4 PLL002: dynamic SQL via `||` at 37, 73, 108 `OPEN..FOR`, 266 `OPEN..FOR`; no other rule) and `corpus/utplsql/core/types/ut_run_info.tpb` (5 PLL002 + 5 PLL007). `ut_run_info.tpb` is a TYPE body, treated as one unit (as above).
- `'select /*+ no_parallel */ '` inside a string literal is a real literal (not a hint): 5 identical occurrences in `ut_run_info.tpb` (23/30/34/39/43); the later literals of those statements differ, so unlabeled.
- Manager: no PLL007. Multi-line `q'[...]'` literals count as one literal each; near-duplicates differ in whitespace/text (e.g. lines 46-47 vs 87-88), `')'` and `'Y'` are exempt/only 2x. `200` (4x) and `250` (2x) occur only in subprogram DECLARE sections (not executable code), so unlabeled.
- Manager PLL004: only `BULK COLLECT INTO` (line 286); PLL006: no TO_DATE; comparisons involve calls, `%rowcount`, `.count`, `ora_sysevent`, not simple typed operands. No COMMIT/ROLLBACK or DML anywhere.
