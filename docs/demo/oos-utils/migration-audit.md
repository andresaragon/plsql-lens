# Sample Oracle → PostgreSQL migration audit: `oos-utils`

*Español: [migration-audit.es.md](migration-audit.es.md).*

This is a **sample** produced with PL/SQL Lens on public code that the tool was not developed against. Numbers come from the tool's
raw output ([`raw/`](raw/)) or from the manual review of a sample (marked as such); the blocks of numbers are generated and checked
by [`tables.py`](tables.py). Read "What this report does not cover" before drawing conclusions.

## 1. Scope

| Item | Value |
|---|---|
| Project | `oos-utils` (OraOpenSource), a PL/SQL utility library |
| URL | https://github.com/OraOpenSource/oos-utils |
| Commit analyzed | `b6217292bc744211eaee9e1d11ca7a0b495bc44d` |
| License | MIT, read in the `LICENSE` file at that commit (copyright 2015 OraOpenSource); SHA-256 of the file in [`raw/meta.txt`](raw/meta.txt) |
| Path analyzed | `source/` (packages, `source/future/` and the SQL scripts). `install/` is left out: its header says it is auto-generated from the same sources, and counting it would count them twice |
| PL/SQL Lens | version 0.1.0; last commit that changed `src/`: `8251b1cdb3687d8ec9204996aae6eb88f909e30c`; migration rules MIG001–MIG011 only |
| Command | `bash scripts/demo_migration_audit.sh` (clones at the fixed commit, runs `plsql-lens migrate` in JSON and table format and `plsql-lens inventory`, writes [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Measure | Value |
|---|---|
| PL/SQL files analyzed | 26 |
| Lines in those files | 6449 |
| Findings | 36 |
| Files with at least one finding | 10 |
| Findings by severity: `high` | 5 |
| Findings by severity: `medium` | 8 |
| Findings by severity: `low` | 23 |
<!-- END:facts -->

The third-party code is not stored in this repository, only the URL, the commit and the tool's output. The excerpts below are
limited to 5 lines each and come from `oos-utils` (MIT, © 2015 OraOpenSource). The sources contain developer attribution tags in
comments (a name and an e-mail address) and one fictitious example address in a comment; no excerpt reproduces them. In `data/`
and `tests/` (not analyzed) I found no personal data by pattern search and a partial read.

## 2. Executive summary

* PL/SQL Lens (migration rules MIG001–MIG011) reports **36 findings in 10 of 26 files**: 5 `high`, 8 `medium`, 23 `low`
  (raw output). The mechanical `low` findings (NVL, `FROM DUAL`, `DBMS_OUTPUT`, one DECODE) are most of the count.
* **Main risks, in business terms:**
  1. *Silent differences with empty text.* The five `high` findings assign `''` (which is NULL in Oracle) to a buffer inside hash
     routines. In my reading the result does not change here, but this is the category of defect that moves a migration from
     "compiles" to "returns different data", and it needs a test, not only a review.
  2. *Time-dependent code.* A wait loop uses `SYSTIMESTAMP`; the replacement the tool suggests (`CURRENT_TIMESTAMP`) is fixed
     during a PostgreSQL transaction and would make that loop never end.
  3. *Oracle-only features around the findings that this version does not look at* (raw-byte functions, XML functions,
     APEX views, dynamic SQL). The 36 findings are what 11 rules see, not an estimate of the work.
* Manual review of a 20-finding sample (Claude, provisional): 16 real hits, 4 doubtful, 0 false positives. Twenty findings
  justify no estimate of precision on the rest.

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
<!-- END:by_rule -->

The ten files with most findings (all files with findings if there are fewer):

<!-- BEGIN:by_file -->
| File | Findings |
|---|---|
| `source/packages/oos_util_crypto.pkb` | 18 |
| `source/scripts/prereqs.sql` | 4 |
| `source/future/oos_util_transform.pkb` | 2 |
| `source/future/reusable_table_create_template.sql` | 2 |
| `source/packages/oos_util.pkb` | 2 |
| `source/packages/oos_util_apex.pkb` | 2 |
| `source/packages/oos_util_string.pkb` | 2 |
| `source/packages/oos_util_totp.pkb` | 2 |
| `source/packages/oos_util_lob.pkb` | 1 |
| `source/scripts/recompile.sql` | 1 |
| **Total** (10) | 36 |
<!-- END:by_file -->

## 4. Main risks

All `high` and `medium` findings were read in context (13 of them: 5 `high`, 8 `medium`). Statements about PostgreSQL are my
reading of the code; **none was run on a database**.

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

## 5. Manual review of a sample

**Method.** The sample is stratified by rule: the first 4 findings of each rule ordered by file path, line and column
(all of them when a rule has fewer than 4). That gives 20 findings. It is reproducible, and it is **not random**: it favors the
files that sort first alphabetically. **The verdicts are a review by Claude, provisional, on a small sample;** they are not
tool output and nobody else has checked them.

*Real hit*: the token is the Oracle construct the rule names and its message fits this use. *Doubtful*: the construct is there but
I could not show that it changes behavior here, or the severity does not fit. *False positive*: the token is something else.

<!-- BEGIN:sample_totals -->
Reviewed sample: 20 findings, 16 real hit, 4 doubtful, 0 false positive.
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
<!-- END:sample -->

The data is in [`review.json`](review.json); [`tables.py`](tables.py) fails if it does not match the selection above. Twenty
findings do not allow an estimate of precision for the 36, and none of the 16 *real hits* says how costly the migration is.

## 6. What this report does not cover

* **Constructs outside the 11 rules of this version.** In this version `BULK COLLECT` / `FORALL`, `EXECUTE IMMEDIATE`,
  `RAISE_APPLICATION_ERROR`, the packages `DBMS_LOB`, `DBMS_SQL` and `UTL_FILE`, and pipelined functions **are not detected**.
  Reading the code I saw, for example, `execute immediate l_sql;` (`reusable_table_create_template.sql:237`), which the tool
  does not report. Other Oracle-only elements that no rule covers also appear (`utl_raw`, `dbms_utility`, XML functions such as
  `existsnode` and `xmlquery`, `bin_to_num`, APEX views).
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
* **The tool's own limits.** The `unit` field of some findings is imprecise: it names `oos_util_crypto.sha256` for lines that, by
  the line ranges I read, belong to `sha512` (line 943) and `randombytes` (lines 1229 and 1237). I report it and did not change the
  tool.
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
