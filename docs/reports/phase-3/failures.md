# F3 — classification of the 15 non-passing tests (final run)

Run: workflow `oracle`, commit `6fa6c8c` (see `report.json`). 405 tests, 390 passed, 8 failed, 7 errored.
"Bad test" = the generated test is wrong; "real defect" = the unit does not do what its own header
comment promises. Each row cites evidence that anyone can re-check.

| Tests | Unit | Class | Evidence |
|---|---|---|---|
| 11 (5 failed + 6 errored) | `logger.log_error` | **bad test** | The tests count rows with `scope = 'TLE_<UPPER HEX>'`, but Logger stores `lower(p_scope)` (`corpus/logger/logger.pkb:2831`). Direct call in a plain session inserts the row: `diag-logger.log` → `rows_after_log_error=1`. |
| 1 (errored) | `logger.get_pref` | **bad test** | The test inserts a preference outside the allowed list; trigger `BIU_LOGGER_PREFS` raises ORA-20000 "restricted to a set list" (`tests/fixtures/testgen/logger/logger_prefs.sql:115`). |
| 2 (failed) | `pkg_text.mask_email` | **real defect** (unplanned, in this repo's own fixture) | Header comment: "Returns NULL when there is no '@'". For NULL / '' input `instr` is NULL, `NULL < 2` is not TRUE, and `substr(NULL,1,1) \|\| '***' \|\| substr(NULL,NULL)` is `'***'` (NULL is the empty string in `\|\|`). Actual `'***'`, expected NULL (`tests/fixtures/testgen/own/pkg_text.sql:23-30`). |
| 1 (failed) | `pkg_text.truncate_text` | **real defect** (same class) | Header comment: "NULL -> NULL". `length(NULL) <= n` is not TRUE, so it returns `substr(NULL,1,n-3) \|\| '...'` = `'...'` (`pkg_text.sql:50-59`). |

Not counted above, found by running rather than by a generated test:
* `pkg_text.is_palindrome` used `REVERSE`, which PL/SQL does not provide (PLS-00201). The whole `pkg_text`
  package body was INVALID in the first Oracle run (all 3 `pkg_text` suites errored with ORA-04063). Fixed in
  the fixture before the v2 generation; round-0 numbers are kept in `history/v1-round0-report.json`.

Caveat on "passed": 11 `logger.log_error` tests are broken by one mistake (upper-case scope), so the
neighbouring tests that expect *no* row ("level OFF suppresses logging", "level PERMANENT suppresses error
logging") pass vacuously. Pass counts say the test ran green, not that it is meaningful.
