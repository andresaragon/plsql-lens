# New migration rules MIG012–MIG017 — counts and a sample review

Work item F5-G4. Contract: [`docs/migration-rules.md`](../migration-rules.md). These rules only **detect and explain**; the
PostgreSQL equivalents in their messages are orientation, not a rewrite, and nothing here ran against a database.

Everything below comes from `plsql-lens migrate corpus --format json` at the commit that adds the rules (264 PL/SQL files).
The counts of MIG001–MIG011 did not change (70, 11, 22, 15, 7, 2, 1, 38, 46, 14, 8 occurrences; the same table as
[`phase-5a.md`](phase-5a.md)); the total went from 234 to 506 findings, the 272 new ones are those of MIG012–MIG017. The
counts of the new rules are also rows of the table in [`phase-5a.md`](phase-5a.md), which `tests/unit/test_migrate_report.py`
checks against a fresh run.

## Counts by rule and severity

Occurrences (one finding per token match) and files with at least one finding. MIG016 decides its severity per package.

| Rule | Severity | Occurrences | Files |
|---|---|---|---|
| MIG012 | medium | 51 | 21 |
| MIG013 | medium | 4 | 3 |
| MIG014 | medium | 49 | 20 |
| MIG015 | medium | 29 | 10 |
| MIG016 | high | 47 | 5 |
| MIG016 | medium | 63 | 13 |
| MIG017 | medium | 29 | 15 |

MIG016 by package: `dbms_lob` 63 (medium), `dbms_sql` 47 (high), `utl_file` 0.

## Counts by file

Only the files with at least one new finding (51 of the 264).

| File | MIG012 | MIG013 | MIG014 | MIG015 | MIG016 | MIG017 |
|---|---|---|---|---|---|---|
| `corpus/logger/logger.pkb` |  |  | 2 | 5 |  |  |
| `corpus/logger/logger_configure.plb` |  |  | 5 |  |  |  |
| `corpus/oracle-db-sample-schemas/hr_code.sql` |  |  |  | 1 |  |  |
| `corpus/oracle-db-sample-schemas/xdbUtilities.sql` |  |  | 4 |  | 22 |  |
| `corpus/utplsql/api/ut.pkb` |  |  | 2 |  |  | 6 |
| `corpus/utplsql/api/ut.pks` |  |  |  |  |  | 6 |
| `corpus/utplsql/api/ut_runner.pkb` | 2 |  |  | 1 |  | 3 |
| `corpus/utplsql/api/ut_runner.pks` |  |  |  |  |  | 3 |
| `corpus/utplsql/core/annotations/ut_annotation_cache_manager.pkb` | 1 |  | 3 |  |  |  |
| `corpus/utplsql/core/annotations/ut_annotation_manager.pkb` | 4 |  | 2 |  |  |  |
| `corpus/utplsql/core/annotations/ut_annotation_parser.pkb` | 1 |  |  |  |  |  |
| `corpus/utplsql/core/annotations/ut_trigger_annotation_parsing.trg` |  |  | 2 |  |  |  |
| `corpus/utplsql/core/annotations/ut_trigger_check.pkb` |  |  | 1 |  |  |  |
| `corpus/utplsql/core/coverage/ut_coverage.pkb` | 1 |  |  |  |  |  |
| `corpus/utplsql/core/coverage/ut_coverage_helper.pkb` | 1 | 1 | 1 |  |  |  |
| `corpus/utplsql/core/coverage/ut_coverage_helper_block.pkb` | 1 |  | 1 |  |  |  |
| `corpus/utplsql/core/coverage/ut_coverage_helper_profiler.pkb` | 1 |  |  |  |  |  |
| `corpus/utplsql/core/coverage/ut_coverage_reporter_base.tpb` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/coverage/ut_coverage_reporter_base.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_buffer_base.tpb` |  |  |  | 4 | 1 |  |
| `corpus/utplsql/core/output_buffers/ut_output_buffer_base.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_bulk_buffer.tpb` | 2 |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_bulk_buffer.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_clob_table_buffer.tpb` | 1 | 1 |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_clob_table_buffer.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_table_buffer.tpb` | 2 |  |  |  |  | 1 |
| `corpus/utplsql/core/output_buffers/ut_output_table_buffer.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/types/ut_executable.tpb` |  |  |  |  | 15 |  |
| `corpus/utplsql/core/types/ut_executable_test.tpb` |  |  | 2 |  |  |  |
| `corpus/utplsql/core/types/ut_output_reporter_base.tpb` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/types/ut_output_reporter_base.tps` |  |  |  |  |  | 1 |
| `corpus/utplsql/core/types/ut_run_info.tpb` | 4 |  | 5 |  |  |  |
| `corpus/utplsql/core/types/ut_suite_item.tpb` |  |  | 2 |  |  |  |
| `corpus/utplsql/core/ut_expectation_processor.pkb` | 1 |  | 5 |  |  |  |
| `corpus/utplsql/core/ut_metadata.pkb` | 1 |  | 6 |  |  |  |
| `corpus/utplsql/core/ut_suite_cache_manager.pkb` | 7 |  |  |  |  |  |
| `corpus/utplsql/core/ut_suite_manager.pkb` | 4 |  |  | 6 |  |  |
| `corpus/utplsql/core/ut_suite_tag_filter.pkb` | 2 |  | 1 | 6 |  |  |
| `corpus/utplsql/core/ut_utils.pkb` | 3 |  | 1 | 1 | 17 |  |
| `corpus/utplsql/expectations/data_values/ut_compound_data_helper.pkb` | 6 | 2 | 2 | 1 | 27 |  |
| `corpus/utplsql/expectations/data_values/ut_compound_data_value.tpb` |  |  |  |  | 2 |  |
| `corpus/utplsql/expectations/data_values/ut_cursor_details.tpb` | 3 |  |  |  | 4 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_anydata.tpb` |  |  | 1 | 2 | 2 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_blob.tpb` |  |  |  |  | 3 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_clob.tpb` |  |  |  |  | 4 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_json.tpb` |  |  |  |  | 2 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_refcursor.tpb` | 3 |  |  | 2 | 6 |  |
| `corpus/utplsql/expectations/data_values/ut_data_value_xmltype.tpb` |  |  |  |  | 1 |  |
| `corpus/utplsql/expectations/matchers/ut_be_within_helper.pkb` |  |  | 1 |  |  |  |
| `corpus/utplsql/reporters/ut_coverage_cobertura_reporter.tpb` |  |  |  |  | 3 |  |
| `corpus/utplsql/reporters/ut_documentation_reporter.tpb` |  |  |  |  | 1 |  |
| **Total** | **51** | **4** | **49** | **29** | **110** | **29** |

## Sample review

**This is a review by Claude, provisional, not ground truth.** I read each finding in its source context and wrote what I
believe the PostgreSQL change would be, from my own knowledge of both databases; I did not run any of it on PostgreSQL or Oracle,
and nobody else has checked it. The sample is the first 5 findings of each rule ordered by path, line and column, so it is
reproducible but not representative (it is dominated by the first files alphabetically). "Real hit" means: the construct named by
the rule is there, in code (not a false match on a name). It says nothing about how hard the migration is.

### MIG012 — `BULK COLLECT` (5 of 51)

| Finding | Line | Real hit | What PostgreSQL needs |
|---|---|---|---|
| `corpus/utplsql/api/ut_runner.pkb:177` | `fetch l_cursor bulk collect into l_results limit c_bulk_limit;` | yes | No `FETCH ... BULK COLLECT ... LIMIT`: the batching loop becomes a row-by-row `FETCH`/`FOR` loop, or the function returns the query with `RETURN QUERY`. |
| `corpus/utplsql/api/ut_runner.pkb:195` | same statement in a second function | yes | Same. |
| `corpus/utplsql/core/annotations/ut_annotation_cache_manager.pkb:130` | `bulk collect into l_result` after a `select` that builds an object per row | yes | `SELECT array_agg(<row constructor>) INTO l_result`; the collection of object types also has to become an array of a composite type. |
| `corpus/utplsql/core/annotations/ut_annotation_manager.pkb:49` | `bulk collect into l_object_to_delete using l_cached_objects` | yes | It is the tail of an `EXECUTE IMMEDIATE` (MIG014 flags the start), so the `INTO` is that of the dynamic statement: PostgreSQL's `EXECUTE ... INTO` takes one row, so the dynamic query must itself aggregate (`array_agg`). |
| `corpus/utplsql/core/annotations/ut_annotation_manager.pkb:96` | `bulk collect into l_result using l_cached_objects, a_modified_after;` | yes | Same as the previous one; `USING` stays but the `:name` markers become `$n`. |

### MIG013 — `FORALL` (4 of 4, the whole population)

| Finding | Line | Real hit | What PostgreSQL needs |
|---|---|---|---|
| `corpus/utplsql/core/coverage/ut_coverage_helper.pkb:37` | `forall i in 1 .. a_data.count` + `insert ... values (a_data(i)...)` | yes | One statement: `INSERT ... SELECT ... FROM unnest(a_data)` (an array of a composite type); the `/*+ no_parallel */` hint is dropped. |
| `corpus/utplsql/core/output_buffers/ut_output_clob_table_buffer.tpb:88` | `forall i in 1 .. a_buffer_rowids.count` + `delete ... where rowid = chartorowid(...)` | yes | `DELETE ... WHERE <key> = ANY(arr)`. It uses `ROWID` and `chartorowid` (no direct equivalent; `ctid` is not stable) and sits in an `AUTONOMOUS_TRANSACTION` (MIG008), so this is more than the `FORALL`. |
| `corpus/utplsql/expectations/data_values/ut_compound_data_helper.pkb:570` | `forall idx in 1..a_diff_tab.count save exceptions` | yes | Set statement as above, but `SAVE EXCEPTIONS` (carry on after failed rows, collect the errors) has no equivalent: an explicit loop with a sub-block per row, or accepting that the statement fails as a whole. |
| `corpus/utplsql/expectations/data_values/ut_compound_data_helper.pkb:748` | `forall i in 1..l_diffs.count` + `insert` | yes | `INSERT ... SELECT ... FROM unnest(l_diffs)`. |

### MIG014 — `EXECUTE IMMEDIATE` (5 of 49)

The text of the dynamic SQL is not analyzed by the rule, so what is said about the string is my reading, not a finding.

| Finding | Line | Real hit | What PostgreSQL needs |
|---|---|---|---|
| `corpus/logger/logger.pkb:769` | `execute immediate l_sql;` (text in a variable, built a few lines above as `'begin ' \|\| l_plugin_fn \|\| '(…); end;'`) | yes | The block calls a function whose name is a run-time value: `EXECUTE format('SELECT %I(...)', …)` or `PERFORM`; an anonymous `begin … end;` string is not valid for `EXECUTE`. The rule cannot see how `l_sql` is built. |
| `corpus/logger/logger.pkb:2550` | `execute immediate 'begin dbms_output.enable(1000000); end;';` | yes | An anonymous block cannot be run with `EXECUTE` in PL/pgSQL, and `DBMS_OUTPUT.ENABLE` has no equivalent: the statement is dropped or redesigned. MIG009 does not see the `dbms_output` inside the string. |
| `corpus/logger/logger_configure.plb:66` | `execute immediate 'select 1 from apex_application_items where rownum = 1' into l_dummy;` | yes | `EXECUTE '...' INTO l_dummy` with `LIMIT 1`. The string contains `ROWNUM` (MIG005 does not see it). The query is a probe for an APEX table, so the error behaviour when the table is missing has to be rechecked. |
| `corpus/logger/logger_configure.plb:82` | `execute immediate 'begin :d := dbms_flashback.get_system_change_number; end; ' using out l_dummy;` | yes | `USING OUT` and a block with a bind output do not exist in PostgreSQL, and `DBMS_FLASHBACK` has no equivalent: a redesign of the check. |
| `corpus/logger/logger_configure.plb:98` | `execute immediate 'begin :x := logger.g_pref_type_logger; end;' using out l_pref_type_logger;` | yes | Reads a package constant through a dynamic block; PostgreSQL has no package constants (package state is out of scope), so this needs a redesign, not a `format()`. |

### MIG015 — `RAISE_APPLICATION_ERROR` (5 of 29)

| Finding | Line | Real hit | What PostgreSQL needs |
|---|---|---|---|
| `corpus/logger/logger.pkb:136` | `raise_application_error(-20000, p_message);` (in the `$else` branch) | yes | `RAISE EXCEPTION '%', p_message USING ERRCODE = '<5-char code>';` the callers that test `SQLCODE = -20000` need that mapping. |
| `corpus/logger/logger.pkb:420` | `raise_application_error (-20000, 'You are not authorized to call this procedure. …')` | yes | Same. |
| `corpus/logger/logger.pkb:2036` | `raise_application_error(-20001, 'Can not set ' \|\| l_pref_type \|\| '. Reserved for Logger');` | yes | Same, with `-20001` mapped to its own `ERRCODE`. |
| `corpus/logger/logger.pkb:2082` | `raise_application_error(-20001, 'Can not delete ' …)` | yes | Same. |
| `corpus/logger/logger.pkb:2359` | `raise_application_error (-20000, 'Either the NO-OP version of Logger is installed …')` (in a `$if $$no_op` block) | yes | Same, and the `$if` conditional compilation around it needs its own port. |

### MIG016 — `DBMS_LOB`, `DBMS_SQL`, `UTL_FILE` (5 of 110, plus 5 `DBMS_SQL`)

The first 5 by path are all `DBMS_LOB` in one file; a second table shows the first 5 `DBMS_SQL` findings (the rule's `high`
ones). `UTL_FILE` has no finding in the corpus, so that package is checked only by the fixtures.

| Finding | Line | Severity | Real hit | What PostgreSQL needs |
|---|---|---|---|---|
| `corpus/oracle-db-sample-schemas/xdbUtilities.sql:290` col 7 | `DBMS_LOB.createTemporary(tempBLOB, true, DBMS_LOB.SESSION);` | medium | yes | A `bytea` variable; there is no temporary-LOB lifecycle or duration. |
| `…xdbUtilities.sql:290` col 48 | the constant `DBMS_LOB.SESSION` on the same line | medium | yes (a constant, not a call) | Disappears with the previous one. |
| `…xdbUtilities.sql:292` | `DBMS_LOB.trim(tempBLOB, 0);` | medium | yes | Slicing/emptying a `bytea` (`substring`, `''::bytea`). |
| `…xdbUtilities.sql:294` col 5 | `DBMS_LOB.fileopen(targetFile, DBMS_LOB.file_readonly);` | medium | yes | `BFILE` has no equivalent: reading a server file needs `pg_read_binary_file` (privileged) or moving the read to the application. |
| `…xdbUtilities.sql:294` col 35 | the constant `DBMS_LOB.file_readonly` | medium | yes (a constant) | Disappears with the previous one. |

| Finding | Line | Severity | Real hit | What PostgreSQL needs |
|---|---|---|---|---|
| `corpus/utplsql/core/types/ut_executable.tpb:155` | `l_cursor_number := dbms_sql.open_cursor;` | high | yes | No cursor-number API; redesign with `EXECUTE`. |
| `…ut_executable.tpb:163` col 9 | `dbms_sql.parse(l_cursor_number, statement => …, language_flag => dbms_sql.native);` | high | yes | Same. |
| `…ut_executable.tpb:163` col 84 | the constant `dbms_sql.native` on the same line | high | yes (a constant) | Disappears with the redesign. |
| `…ut_executable.tpb:164` | `dbms_sql.bind_variable(l_cursor_number, 'a_error_stack', …)` | high | yes | `USING` of `EXECUTE`; the bind-by-name loop has to be rewritten. |
| `…ut_executable.tpb:165` | `dbms_sql.bind_variable(l_cursor_number, 'a_error_backtrace', …)` | high | yes | Same. |

### MIG017 — `PIPELINED` (5 of 29)

| Finding | Line | Real hit | What PostgreSQL needs |
|---|---|---|---|
| `corpus/utplsql/api/ut.pkb:257` | `) return ut_varchar2_rows pipelined is` | yes | `RETURNS SETOF varchar` (or `RETURNS TABLE`) with `RETURN NEXT`; the `PIPE ROW` statements go away and the collection type `ut_varchar2_rows` is no longer needed. |
| `corpus/utplsql/api/ut.pkb:305` | same signature | yes | Same. |
| `corpus/utplsql/api/ut.pkb:354` | same signature | yes | Same. |
| `corpus/utplsql/api/ut.pkb:403` | same signature | yes | Same. |
| `corpus/utplsql/api/ut.pkb:452` | same signature | yes | Same. |

Result of this sample: 29 findings read plus 5 more of `DBMS_SQL`, all 34 real in the sense above. With a 5-per-rule, path-ordered
sample that says nothing about precision on the rest.

## Observations on the contracts (reported, not tuned)

* **Nothing matched something that is not what the rule names.** In particular all 49 MIG014 findings are `execute immediate`
  statements in code, and no MIG013/MIG017 finding is a name collision. I did not adjust any rule after seeing the counts.
* **MIG016 counts references, not routines.** A `DBMS_SQL` cursor routine such as `ut_executable.tpb` gives 13 findings, and a
  constant used as an argument (`dbms_sql.native`, `dbms_lob.session`) counts as much as a call; so 110 does not mean 110 places
  to redesign. This follows the contract ("followed by `.` and an identifier"); it is a reading caveat, not an error.
* **`DBMS_LOB` is `medium` as a package, but its file routines are closer to `UTL_FILE`.** `fileopen` / `loadblobfromfile` on a
  `BFILE` (the sample above, `xdbUtilities.sql`) have no PostgreSQL equivalent, as with `UTL_FILE`. The contract fixes the severity
  by package, so those findings are `medium`; if that is too low, the severity table of the contract is what would change.
* **MIG017 counts each function twice** (specification and body): 29 findings are 15 declarations plus 14 bodies, in 7 pairs of
  files plus one specification (`ut_output_buffer_base.tps`) whose body has no `pipelined`. See the contract.
* **MIG012 and MIG014 overlap on dynamic queries:** `execute immediate … bulk collect into` is two findings, one per rule, by
  design.
* **MIG014 does not see inside the string**, as the contract says: for example the `rownum` and `dbms_output` inside the strings
  at `logger_configure.plb:66` and `logger.pkb:2550` are not reported by MIG005 or MIG009.

## Not verified

* No PostgreSQL or Oracle run: the equivalents in the sample are my reading, not a tested result.
* The sample is 5 per rule (plus 5 `DBMS_SQL`), the first by path and line; precision on the other findings is unknown.
* `UTL_FILE` has no finding in `corpus/`: the rule is tested only on fixtures written from the contract.
* The spend is reported in the pull request.
