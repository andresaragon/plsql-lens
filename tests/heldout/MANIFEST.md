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
