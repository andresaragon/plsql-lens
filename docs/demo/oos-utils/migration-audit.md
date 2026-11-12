# Sample Oracle → PostgreSQL migration audit: `oos-utils`

*Español: [migration-audit.es.md](migration-audit.es.md).*

This is a **sample** produced with PL/SQL Lens on public code that the tool was not developed against. Numbers come from the tool's
raw output ([`raw/`](raw/)) or from the manual review of a sample (marked as such); the blocks of numbers are generated and checked
by [`tables.py`](tables.py). Read "What this report does not cover" before drawing conclusions.

**Revision 2 (2026-11-04).** First published with the rules MIG001–MIG011 (36 findings, a 20-finding review sample). Regenerated after the rules MIG012–MIG017 were merged (95 findings, a 37-finding sample); the text of section 4.6 and the counts that changed are new, the rest is as before. The first revision stays in the git history of this file.

## 1. Scope

| Item | Value |
|---|---|
| Project | `oos-utils` (OraOpenSource), a PL/SQL utility library |
| URL | https://github.com/OraOpenSource/oos-utils |
| Commit analyzed | `b6217292bc744211eaee9e1d11ca7a0b495bc44d` |
| License | MIT, read in the `LICENSE` file at that commit (copyright 2015 OraOpenSource); SHA-256 of the file in [`raw/meta.txt`](raw/meta.txt) |
| Path analyzed | `source/` (packages, `source/future/` and the SQL scripts). `install/` is left out: its header says it is auto-generated from the same sources, and counting it would count them twice |
| PL/SQL Lens | version 0.1.0; last commit that changed `src/`: `558dcee3664ca4c794e723f9c1ee574350420c1e`; migration rules MIG001–MIG017 |
| Command | `bash scripts/demo_migration_audit.sh` (clones at the fixed commit, runs `plsql-lens migrate` in JSON and table format and `plsql-lens inventory`, writes [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Measure | Value |
|---|---|
| PL/SQL files analyzed | 26 |
| Lines in those files | 6449 |
| Findings | 95 |
| Files with at least one finding | 14 |
| Findings by severity: `high` | 18 |
| Findings by severity: `medium` | 54 |
| Findings by severity: `low` | 23 |
<!-- END:facts -->

The third-party code is not stored in this repository, only the URL, the commit and the tool's output. The excerpts below are
limited to 5 lines each and come from `oos-utils` (MIT, © 2015 OraOpenSource). The sources contain developer attribution tags in
comments (a name and an e-mail address) and one fictitious example address in a comment; no excerpt reproduces them. In `data/`
and `tests/` (not analyzed) I found no personal data by pattern search and a partial read.

## 2. Executive summary

* PL/SQL Lens (migration rules MIG001–MIG017) reports **95 findings in 14 of 26 files**: 18 `high`, 54 `medium`, 23 `low`
  (raw output). 36 come from MIG001–MIG011 and 59 from the six rules added after the first revision (MIG012–MIG017). The 23 `low`
  findings are mechanical (NVL, `FROM DUAL`, `DBMS_OUTPUT`, one DECODE). MIG016 counts references to `DBMS_LOB` and `DBMS_SQL`
  (types and constants too), not routines to redesign.
* **Main risks, in business terms:**
  1. *Silent differences with empty text.* Five of the `high` findings (MIG011) assign `''` (which is NULL in Oracle) to a buffer inside hash
     routines. In my reading the result does not change here, but this is the category of defect that moves a migration from
     "compiles" to "returns different data", and it needs a test, not only a review.
  2. *Time-dependent code.* A wait loop uses `SYSTIMESTAMP`; the replacement the tool suggests (`CURRENT_TIMESTAMP`) is fixed
     during a PostgreSQL transaction and would make that loop never end (issue #3).
  3. *Code that has to be redesigned, not ported.* All 13 `DBMS_SQL` findings (`high`) are in one routine that turns a REF CURSOR
     into a `DBMS_SQL` cursor and describes its columns; PostgreSQL has no equivalent API (section 4.6).
  4. *Oracle-only features around the findings that this version does not look at* (raw-byte functions, XML functions,
     APEX views, and the text inside dynamic SQL, which the rules flag but do not read). The 95 findings are what 17 rules see,
     not an estimate of the work.
* Manual review of a 37-finding sample (Claude, provisional): 33 real hits, 4 doubtful, 0 false positives. Thirty-seven findings
  justify no estimate of precision on the other 58.

## 3. Findings by rule and severity, and by file

Raw output: [`raw/migrate.json`](raw/migrate.json), [`raw/migrate.txt`](raw/migrate.txt).

<!-- BEGIN:by_rule -->
| Rule | Severity | Occurrences | Files |
|---|---|---|---|
| MIG001 | low | 14 | 3 |
| MIG002 | low | 1 | 1 |
| MIG003 | medium | 6 | 3 |
| MIG009 | low | 5 | 2 |
| MIG010 | low | 3 | 2 |
| MIG011 | high | 5 | 1 |
| MIG011 | medium | 2 | 2 |
| MIG012 | medium | 2 | 1 |
| MIG014 | medium | 13 | 3 |
| MIG015 | medium | 3 | 2 |
| MIG016 | high | 13 | 1 |
| MIG016 | medium | 24 | 5 |
| MIG017 | medium | 4 | 2 |
<!-- END:by_rule -->

The ten files with most findings (all files with findings if there are fewer):

<!-- BEGIN:by_file -->
| File | Findings |
|---|---|
| `source/future/oos_util_transform.pkb` | 21 |
| `source/packages/oos_util_crypto.pkb` | 18 |
| `source/future/reusable_table_create_template.sql` | 15 |
| `source/packages/oos_util_lob.pkb` | 15 |
| `source/packages/oos_util_string.pkb` | 6 |
| `source/scripts/prereqs.sql` | 6 |
| `source/packages/oos_util.pkb` | 3 |
| `source/packages/oos_util_apex.pkb` | 2 |
| `source/packages/oos_util_string.pks` | 2 |
| `source/packages/oos_util_totp.pkb` | 2 |
| **Total** (14) | 95 |
<!-- END:by_file -->

## 4. Main risks

The 13 `high` and `medium` findings of MIG001–MIG011 (5 `high`, 8 `medium`) were read in context. Of the 59 findings of
MIG012–MIG017, only the 17 of the sample in section 5 were read, and 4.6 describes what that reading showed. Statements about
PostgreSQL are my reading of the code; **none was run on a database**.

### 4.1 `''` assigned to a variable (MIG011, `high`) — `oos_util_crypto.pkb:229, 383, 517, 771, 943`

```plsql
          else
            t_msg_buf := '';
          end if;
```
*(`source/packages/oos_util_crypto.pkb:228-230`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** in Oracle `''` is NULL; in PostgreSQL it is an empty string. The tool rates any `''` that is not in a
  concatenation or a `replace` argument as `high`.
* **Reading:** the buffer is later concatenated (`t_msg_buf || t_pad`) and measured with `nvl(length(t_msg_buf), 0)`, and I
  found no path where NULL and `''` give different results. I classify these as *doubtful* (the construct is there; the damage
  is not evident). The same pattern appears in each of the five hash routines (by the line ranges I read: `ripemd160`, `md4`,
  `md5`, `sha256` and `sha512`).
* **What to do:** assign `NULL` explicitly, or keep `''` and check the `IS NULL` tests; test each routine against known
  digests, since a wrong hash would not raise an error.

### 4.2 `SYSTIMESTAMP` in a wait loop (MIG003, `medium`) — `oos_util.pkb:105, 113`

```plsql
    -- Note: Can't use systimestamp in loop since it doesn't seem to calculate a new timestamp each iteration.
    while(l_end_time > l_now) loop
      l_now := systimestamp;
    end loop;
```
*(`source/packages/oos_util.pkb:111-114`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** the tool's hint lists `CURRENT_TIMESTAMP`, `LOCALTIMESTAMP` or `CURRENT_DATE`. In PostgreSQL
  `CURRENT_TIMESTAMP` is the start of the transaction, so this loop would not end if the hint were applied literally.
* **What to do:** `pg_sleep(p_seconds)` replaces the whole procedure; if the loop is kept, `clock_timestamp()` is the function
  that advances.

### 4.3 `SYSDATE` over an APEX view (MIG003, `medium`) — `oos_util_apex.pkb:104-105`

```plsql
    and aws.apex_session_id = p_session_id
    and sysdate <= aws.session_idle_timeout_on
    and sysdate <= aws.session_life_timeout_on;
```
*(`source/packages/oos_util_apex.pkb:103-105`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** the comparison itself ports (`LOCALTIMESTAMP` or `now()`); the table it reads (`apex_workspace_sessions`) is
  an Oracle APEX view and does not exist in PostgreSQL.
* **What to do:** decide first whether this function has a PostgreSQL counterpart at all; the date function is the small part.

### 4.4 `SYSTIMESTAMP` as seed material (MIG003, `medium`) — `oos_util_crypto.pkb:1229, 1237`

```plsql
      t_seed := utl_raw.cast_from_number( dbms_utility.get_cpu_time )
             || utl_raw.cast_from_number( extract( second from systimestamp ) )
             || utl_raw.cast_from_number( dbms_utility.get_time );
```
*(`source/packages/oos_util_crypto.pkb:1228-1230`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** `SYSTIMESTAMP` becomes `clock_timestamp()`, but the line also uses `utl_raw` and `dbms_utility`, which have
  no direct equivalent in PostgreSQL. The tool reports only the time function.
* **What to do:** replace the random-byte generator with a PostgreSQL one (for example from the `pgcrypto` extension) instead of
  porting the seed.

### 4.5 `''` as a `replace` argument (MIG011, `medium`) — `reusable_table_create_template.sql:235`, `oos_util_totp.pkb:116`

```plsql
        l_sql := replace(l_sql, '%default_val%', replace(l_columns (i).default_val, 'default', ''));
```
*(`source/future/reusable_table_create_template.sql:235`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** an empty replacement gives the same result unless it empties the whole string (then Oracle returns NULL and
  PostgreSQL `''`). In the line above the result only feeds another `replace`, where a NULL replacement also removes the text, so
  I see no change in behavior (*doubtful*). I did not review `oos_util_totp.pkb:116` beyond reading the line
  (`regexp_replace(..., ':|;', '')`), where the same rule applies.
* **What to do:** nothing unless the value can be exactly the removed text and is then tested for NULL.

### 4.6 Dynamic SQL and `DBMS_SQL` (MIG014 and MIG016) — `oos_util_transform.pkb`, `reusable_table_create_template.sql`

```plsql
    v_cur_id := dbms_sql.to_cursor_number(p_rc);

    dbms_sql.describe_columns3(v_cur_id, v_col_count, v_col_desc);
```
*(`source/future/oos_util_transform.pkb:218-220`, oos-utils, MIT, © 2015 OraOpenSource)*

* **What changes:** all 13 `DBMS_SQL` findings are in this one routine of a file under `source/future/`: it converts a REF CURSOR
  into a `DBMS_SQL` cursor and describes its columns to write text. PostgreSQL has no cursor-number API, so in my reading this is a
  redesign and not a port. Of the 13 `EXECUTE IMMEDIATE` findings (MIG014), 11 are in a table-creation template script that
  builds `CREATE` / `ALTER` text from constants with `replace()` and runs it; each statement ports as `EXECUTE`, but the DDL text
  is not analyzed by the rule.
* **What to do:** decide first whether the code under `source/future/` is in the migration scope: it holds 24 of these 26
  findings. I did not check whether the rest of the project uses it.

## 5. Manual review of a sample

**Method.** The sample is stratified by rule: the first 4 findings of each rule ordered by file path, line and column
(all of them when a rule has fewer than 4). That gives 37 findings. It is reproducible, and it is **not random**: it favors the
files that sort first alphabetically. **The verdicts are a review by Claude, provisional, on a small sample;** they are not
tool output and nobody else has checked them.

*Real hit*: the token is the Oracle construct the rule names and its message fits this use. *Doubtful*: the construct is there but
I could not show that it changes behavior here, or the severity does not fit. *False positive*: the token is something else.

<!-- BEGIN:sample_totals -->
Reviewed sample: 37 findings, 33 real hit, 4 doubtful, 0 false positive.
<!-- END:sample_totals -->

<!-- BEGIN:sample -->
| # | Rule | Severity | Location | Verdict | Reason |
|---|---|---|---|---|---|
| 1 | MIG001 | low | `source/packages/oos_util_crypto.pkb:196` | real hit | NVL around utl_raw.length: a mechanical COALESCE; utl_raw.length itself has no PostgreSQL equivalent (not reported by this version). |
| 2 | MIG001 | low | `source/packages/oos_util_crypto.pkb:231` | real hit | NVL around length() of a buffer that may be ''; COALESCE works, and in PostgreSQL length('') is 0, so the guard is harmless. |
| 3 | MIG001 | low | `source/packages/oos_util_crypto.pkb:355` | real hit | Same pattern as line 196 (NVL around utl_raw.length). |
| 4 | MIG001 | low | `source/packages/oos_util_crypto.pkb:385` | real hit | Same pattern as line 231. |
| 5 | MIG002 | low | `source/scripts/recompile.sql:14` | real hit | DECODE with one literal search value: exact as a CASE. The whole script (user_objects, ALTER PACKAGE ... COMPILE) is an Oracle install helper with no PostgreSQL counterpart. |
| 6 | MIG003 | medium | `source/packages/oos_util.pkb:105` | real hit | SYSTIMESTAMP in a busy-wait sleep(). The tool's hint (CURRENT_TIMESTAMP, ...) would be wrong here: in PostgreSQL it is fixed for the transaction, so a literal swap would never leave the loop; clock_timestamp() or pg_sleep() is needed (my reading, not tested). |
| 7 | MIG003 | medium | `source/packages/oos_util.pkb:113` | real hit | Same loop as line 105: the value is re-read on every iteration. |
| 8 | MIG003 | medium | `source/packages/oos_util_apex.pkb:104` | real hit | SYSDATE compared with a timestamp column of an APEX view; the comparison ports, but the view itself does not exist in PostgreSQL. |
| 9 | MIG003 | medium | `source/packages/oos_util_apex.pkb:105` | real hit | Same query as line 104. |
| 10 | MIG009 | low | `source/future/reusable_table_create_template.sql:315` | real hit | Debug output of a generated statement; RAISE NOTICE, mechanical. |
| 11 | MIG009 | low | `source/scripts/prereqs.sql:23` | real hit | Output of an installation check script; mechanical, but the script is an anonymous block run from SQL*Plus. |
| 12 | MIG009 | low | `source/scripts/prereqs.sql:32` | real hit | Same script as line 23 (error message). |
| 13 | MIG009 | low | `source/scripts/prereqs.sql:40` | real hit | Same script as line 23 (success message). |
| 14 | MIG010 | low | `source/future/oos_util_transform.pkb:75` | real hit | FROM DUAL in a query that also uses existsnode (an Oracle XML function): dropping FROM is trivial, the XML function needs its own rewrite and is not reported. |
| 15 | MIG010 | low | `source/future/oos_util_transform.pkb:121` | real hit | FROM DUAL around xmlquery(...); same remark as line 75. |
| 16 | MIG010 | low | `source/packages/oos_util_totp.pkb:182` | real hit | FROM DUAL after an expression with bin_to_num and to_char(..., 'x'); the FROM goes away, those two functions need review and are not reported. |
| 17 | MIG011 | medium | `source/future/reusable_table_create_template.sql:235` | doubtful | '' as the replacement of replace(): the construct is there, but the result only goes into another replace() whose NULL replacement also removes the text, so I see no change in behavior here. |
| 18 | MIG011 | high | `source/packages/oos_util_crypto.pkb:229` | doubtful | Severity high, but the buffer is then only concatenated and measured with NVL(LENGTH(...)); I found no path where NULL versus '' changes the result (a reading, not a proof). |
| 19 | MIG011 | high | `source/packages/oos_util_crypto.pkb:383` | doubtful | Same pattern as line 229, in another hash function. |
| 20 | MIG011 | high | `source/packages/oos_util_crypto.pkb:517` | doubtful | Same pattern as line 229, in another hash function. |
| 21 | MIG012 | medium | `source/future/reusable_table_create_template.sql:190` | real hit | SELECT ... BULK COLLECT INTO a collection of constraint names read from user_constraints: PostgreSQL needs SELECT array_agg(...) INTO, and user_constraints is an Oracle dictionary view with no direct counterpart (not reported by this version). |
| 22 | MIG012 | medium | `source/future/reusable_table_create_template.sql:329` | real hit | Same pattern as line 190, reading user_triggers. |
| 23 | MIG014 | medium | `source/future/reusable_table_create_template.sql:94` | real hit | Dynamic DDL: l_sql is the template constant c_table_sql with %table_name% replaced. EXECUTE l_sql ports, but the rule does not analyze the DDL text, so Oracle-only syntax inside it would need its own review. |
| 24 | MIG014 | medium | `source/future/reusable_table_create_template.sql:129` | real hit | Dynamic ALTER TABLE ... ADD built from c_add_column_sql with replace(); the data type comes from a variable. Same remark as line 94: the text of the DDL is not analyzed. |
| 25 | MIG014 | medium | `source/future/reusable_table_create_template.sql:159` | real hit | Dynamic ALTER TABLE ... DROP COLUMN from c_drop_column_sql; same remark as line 94. |
| 26 | MIG014 | medium | `source/future/reusable_table_create_template.sql:177` | real hit | Dynamic CREATE SEQUENCE from c_sequence_sql (a q'!...!' literal); same remark as line 94. |
| 27 | MIG015 | medium | `source/packages/oos_util.pkb:70` | real hit | Call with the package constant gc_assert_error_number (-20000, defined at line 5 of the body): the rule does not see the value. Callers that test SQLCODE = -20000 need the mapping to an ERRCODE. |
| 28 | MIG015 | medium | `source/scripts/prereqs.sql:46` | real hit | -20000 in an anonymous block of the SQL*Plus installation check; RAISE EXCEPTION ... USING ERRCODE ports the call, but the script as a whole is an Oracle install helper. |
| 29 | MIG015 | medium | `source/scripts/prereqs.sql:51` | real hit | -20001, same script and remark as line 46. |
| 30 | MIG016 | high | `source/future/oos_util_transform.pkb:206` | real hit | A variable declared with the type dbms_sql.desc_tab3: the rule counts the type reference. The routine describes the columns of an arbitrary cursor with DBMS_SQL (describe_columns3), which has no PostgreSQL counterpart: a redesign, not a port. |
| 31 | MIG016 | medium | `source/future/oos_util_transform.pkb:214` | real hit | dbms_lob.createtemporary for a local CLOB: in PostgreSQL the value is a text variable; there is no temporary-LOB lifecycle or duration. |
| 32 | MIG016 | medium | `source/future/oos_util_transform.pkb:216` | real hit | The constant dbms_lob.call used as an argument of the previous call (it counts as a hit by the contract); it disappears with that call. |
| 33 | MIG016 | high | `source/future/oos_util_transform.pkb:218` | real hit | dbms_sql.to_cursor_number turns a REF CURSOR into a DBMS_SQL cursor number: there is no equivalent, and the rest of the routine depends on it. |
| 34 | MIG017 | medium | `source/packages/oos_util_string.pkb:455` | real hit | Pipelined function (listunagg, varchar2 overload) in the body: RETURNS SETOF with RETURN NEXT, and PIPE ROW goes away. The return type oos_util.tab_vc2 is a collection type. |
| 35 | MIG017 | medium | `source/packages/oos_util_string.pkb:484` | real hit | The second overload of listunagg (clob), in the body; same remark as line 455. |
| 36 | MIG017 | medium | `source/packages/oos_util_string.pks:81` | real hit | The same function in the package specification: the contract counts specification and body, so one function gives two findings. |
| 37 | MIG017 | medium | `source/packages/oos_util_string.pks:86` | real hit | Specification of the clob overload; same remark as line 81. |
<!-- END:sample -->

The data is in [`review.json`](review.json); [`tables.py`](tables.py) fails if it does not match the selection above. Thirty-seven
findings do not allow an estimate of precision for the 95, and none of the 33 *real hits* says how costly the migration is.

## 6. What this report does not cover

* **Constructs outside the 17 rules of this version.** `BULK COLLECT` / `FORALL`, `EXECUTE IMMEDIATE`,
  `RAISE_APPLICATION_ERROR`, the packages `DBMS_LOB`, `DBMS_SQL` and `UTL_FILE`, and pipelined functions are detected since
  MIG012–MIG017, which only detect and never rewrite, and the text inside dynamic SQL is not analyzed. Other Oracle-only
  elements that no rule covers also appear (`utl_raw`, `dbms_utility`, XML functions such as `existsnode` and `xmlquery`,
  `bin_to_num`, APEX views).
* **The out-of-scope list of the contract** ([`docs/migration-rules.md`](../../migration-rules.md)): data types, package state
  (package-level variables and initialization), DDL, and rewriting code. The tool reports; it does not convert.
* **Dynamic SQL.** Text inside string literals is opaque to every rule: an Oracle construct in a string is never reported.
* **Data types.** `NUMBER`, `VARCHAR2`, `DATE`, `RAW`, LOBs and the rest of the type mapping are not examined.
* **Performance.** Nothing here says how the code would perform in PostgreSQL: plans, indexes, hints, parallelism.
* **Equivalence with real data.** No test compared results on Oracle and PostgreSQL for this code. Every statement about
  PostgreSQL behavior is a reading of the code.
* **False negatives.** The rules match tokens, without semantics: a user-defined `nvl`, a `decode` of another package or a quoted
  identifier is not told apart, and a construct hidden in a string, or written in a way the contract does not list (for example
  `FROM SYS.DUAL`), is missed. The precision above is about what was reported; nothing is known about what was not.
* **A single project, a single commit.** Nothing here generalizes to other code bases.

## 7. What a full audit would look like

1. **Inventory.** Units, subprograms, parameters and the call graph (`plsql-lens inventory`), plus a list of the Oracle
   features each unit depends on beyond what the rules cover.
2. **Findings.** The migration rules on the whole code base, with the newest rule set, and a list of constructs that
   no rule covers, built by reading.
3. **Human review.** A person with Oracle and PostgreSQL experience reviews the findings and the code around them, decides what
   is rewritten, replaced or redesigned, and records each decision.
4. **Differential tests.** Selected routines run on Oracle and on PostgreSQL with the same inputs, and their results are
   compared, with the differences classified. This is the only step that gives evidence of equivalent behavior.
5. **Report.** Findings, decisions and test results, and what remains unverified.

## 8. How to reproduce

```bash
bash scripts/demo_migration_audit.sh                 # clone at the fixed commit, run the tool, write docs/demo/oos-utils/raw/
uv run python docs/demo/oos-utils/tables.py          # check that the numbers of both reports match raw/ and review.json
```

Needs `git`, `uv` and network access to github.com. The same commit gives the same findings.
