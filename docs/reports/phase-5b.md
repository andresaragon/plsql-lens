# Phase F5b report — safe rewrite, checked on PostgreSQL

Branch `feat/f5-rewrite`, one draft PR on `main` @ `4aaacb1`. Independent of F5a (it imports neither the rules nor the CLI).

## What was built

* **`plsql_lens.migrate.rewrite.rewrite_sql(sql) -> Rewrite(sql, applied, skipped)`**: four mechanical rewrites, named by the
  migration rule ids: MIG001 `NVL(a, b)` → `COALESCE(a, b)`; MIG002 `DECODE(...)` → `CASE`; MIG004 `seq.NEXTVAL` /
  `sch.seq.CURRVAL` → `nextval('seq')` / `currval('sch.seq')`; MIG010 `FROM DUAL` dropped.
* **Where the text comes from.** `parser.lexer.tokenize` finds the constructs; it drops comments and keeps no offsets, so each
  token's span is recomputed from its line and column in the original text. Only the spans of the rewritten constructs change;
  everything else (spacing, line breaks, case, comments) is copied byte for byte. Strings, comments and quoted identifiers are never
  matched.
* **`DECODE` and `NULL`.** `DECODE` matches NULL with NULL; `CASE x WHEN NULL` never does. Without a literal `NULL` search value the
  result is `CASE e WHEN s THEN r … ELSE d END`. With one, it is `CASE WHEN e IS NULL THEN r WHEN e = s THEN r …`, which needs `e`
  more than once: if `e` is not simple (it has a call, a sequence or a subquery) the construct is skipped, never rewritten wrongly.
* **Conservative.** A construct that cannot be rewritten is left exactly as it was and listed in `skipped` with its reason:
  unbalanced parentheses, a comment inside `DECODE` / the sequence name / `FROM DUAL`, impossible arity (`NVL` needs two arguments,
  `DECODE` at least three, no empty argument), a remote sequence (`seq.nextval@db`), `FROM DUAL` with an alias, in a join or
  followed by another clause (`SELECT *`, `DELETE FROM DUAL` too). A skipped outer construct does not stop the inner ones from being
  rewritten. A comment inside an `NVL` call does not matter: only its name changes.
* **Idempotent.** A second pass runs only while the text changes (odd input such as `from dual from dual` can expose a new match), so
  `rewrite_sql(rewrite_sql(x).sql).sql == rewrite_sql(x).sql`; `applied` lists every rewrite made.
* **Proof on PostgreSQL**: `tests/integration/test_migrate_postgres.py` runs each rewritten case of
  `tests/fixtures/migrate/semantics.json` (results observed on Oracle Free 23.26.3, read-only) through `PLSQL_LENS_PSQL` (a `psql`
  shell command; no Python driver), wrapped as `select coalesce(cast(x as text), '<NULL>') from (<sql>) t(x)`, after the case's
  `setup`; and `.github/workflows/postgres.yml` runs it on `postgres:16` and publishes the results to branch `ci-results/f5`.
* Tests were committed red first (collection error: no `rewrite` module), in their own commit.

## Result on PostgreSQL

The rewritten statements were run twice, with identical per-case results (same rewritten SQL, same PostgreSQL output, same status):

* **CI**, workflow `postgres` run 41117304825 on commit `8362eea`, image `postgres:16` = **PostgreSQL 16.15 (Debian 16.15-1.pgdg13+2)**:
  39 tests passed (37 cases, the version check and the report writer). Results published to branch `ci-results/f5`
  (`results.json`, `pytest.log`, `version.txt`, `commit.txt`).
* **Local**, PostgreSQL 16.15 (Ubuntu build) over a unix socket, before the push.


| Result | Cases |
|---|---|
| Same as `oracle_result` | **32** |
| Differ from `oracle_result`, equal to `pg_naive_result` (documented `known_divergence`) | **5** |
| Mismatch (should match, does not) | 0 |
| Unexpected (a divergent case that matches Oracle) | 0 |

### Known divergences (the rewrite is correct; PostgreSQL differs for a reason outside it)

| Case | Reason | Oracle | PostgreSQL |
|---|---|---|---|
| nvl_08 | `oracle_empty_string_is_null`: `NVL('', 'x')`, `''` is NULL only on Oracle | `x` | empty string |
| nvl_09 | `oracle_empty_string_is_null`: `TRIM('  ')` is `''` | `blank` | empty string |
| nvl_10 | `oracle_empty_string_is_null`: `SUBSTR('abc', 5)` is `''` | `e` | empty string |
| nvl_11 | `oracle_concat_ignores_null`: `'abc' \|\| NULL` is `'abc'` on Oracle, NULL on PostgreSQL | `abc` | `z` |
| decode_11 | `oracle_empty_string_is_null`: `DECODE('', NULL, …)` | `isnull` | `notnull` |

These are the cases where detection by the F5a rules (MIG011 for `''`) matters more than the rewrite.

### Finding fixed in the rewrite: an untyped `NULL` after `CASE`

The first run on PostgreSQL gave 36 / 37: `decode_06` (`DECODE(NULL, 1, 'a', 'z')`) failed to compile, because the rewrite
`CASE NULL WHEN 1 THEN 'a' ELSE 'z' END` types the untyped `NULL` as `text` (`operator does not exist: text = integer`). The unit
tests could not see it, and no case was edited: the rewrite now uses the `CASE WHEN NULL = 1 THEN …` form for a literal `NULL` subject
(a unit test pins it) and the case passes. Without a real PostgreSQL this would have shipped.

## Every case

`oracle_result` is from `semantics.json`; the PostgreSQL column is what the rewritten statement returned.

| Case | Rewritten SQL | Oracle | PostgreSQL | Status |
|---|---|---|---|---|
| nvl_01 | `SELECT COALESCE(NULL, 'x')` | `x` | `x` | match |
| nvl_02 | `SELECT COALESCE('a', 'x')` | `a` | `a` | match |
| nvl_03 | `SELECT COALESCE(NULL, 5)` | `5` | `5` | match |
| nvl_04 | `SELECT COALESCE(COALESCE(NULL, 3), 7)` | `3` | `3` | match |
| nvl_05 | `SELECT COALESCE(NULL, NULL)` | `<NULL>` | `<NULL>` | match |
| nvl_06 | `SELECT COALESCE(1 + 2, 0)` | `3` | `3` | match |
| nvl_07 | `SELECT COALESCE(NULLIF(1, 1), 9)` | `9` | `9` | match |
| nvl_08 | `SELECT COALESCE('', 'x')` | `x` | `''` (empty) | divergent as documented |
| nvl_09 | `SELECT COALESCE(TRIM('  '), 'blank')` | `blank` | `''` (empty) | divergent as documented |
| nvl_10 | `SELECT COALESCE(SUBSTR('abc', 5), 'e')` | `e` | `''` (empty) | divergent as documented |
| nvl_11 | `SELECT COALESCE('abc' \|\| NULL, 'z')` | `abc` | `z` | divergent as documented |
| decode_01 | `SELECT CASE 1 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END` | `a` | `a` | match |
| decode_02 | `SELECT CASE 2 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END` | `b` | `b` | match |
| decode_03 | `SELECT CASE 3 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END` | `c` | `c` | match |
| decode_04 | `SELECT CASE 3 WHEN 1 THEN 'a' WHEN 2 THEN 'b' END` | `<NULL>` | `<NULL>` | match |
| decode_05 | `SELECT CASE WHEN NULL IS NULL THEN 'isnull' ELSE 'notnull' END` | `isnull` | `isnull` | match |
| decode_06 | `SELECT CASE WHEN NULL = 1 THEN 'a' ELSE 'z' END` | `z` | `z` | match |
| decode_07 | `SELECT CASE 'x' WHEN 'x' THEN 1 WHEN 'y' THEN 2 END` | `1` | `1` | match |
| decode_08 | `SELECT CASE 1 + 1 WHEN 2 THEN 'two' ELSE 'other' END` | `two` | `two` | match |
| decode_09 | `SELECT CASE CASE 1 WHEN 1 THEN 2 ELSE 3 END WHEN 2 THEN 'ok' ELSE 'no' END` | `ok` | `ok` | match |
| decode_10 | `SELECT CASE WHEN NULL = 1 THEN 'a' WHEN NULL IS NULL THEN 'n' ELSE 'd' END` | `n` | `n` | match |
| decode_11 | `SELECT CASE WHEN '' IS NULL THEN 'isnull' ELSE 'notnull' END` | `isnull` | `notnull` | divergent as documented |
| decode_12 | `SELECT CASE 2 WHEN 1 THEN 'a' WHEN 2 THEN 'b' WHEN 2 THEN 'c' END` | `b` | `b` | match |
| nextval_01 | `SELECT nextval('f5_s1')` | `5` | `5` | match |
| nextval_02 | `SELECT nextval('f5_s2')` | `10` | `10` | match |
| nextval_03 | `SELECT nextval('f5_s3') + currval('f5_s3')` | `2` | `2` | match |
| nextval_04 | `SELECT 'id-' \|\| nextval('f5_s4')` | `id-100` | `id-100` | match |
| nextval_05 | `SELECT nextval('f5_s5') * 2` | `42` | `42` | match |
| nextval_06 | `SELECT nextval('F5_S6')` | `7` | `7` | match |
| from_dual_01 | `SELECT 1` | `1` | `1` | match |
| from_dual_02 | `SELECT 'a' \|\| 'b'` | `ab` | `ab` | match |
| from_dual_03 | `SELECT 1 + 1` | `2` | `2` | match |
| from_dual_04 | `SELECT   2 * 3` | `6` | `6` | match |
| from_dual_05 | `SELECT 'x' WHERE 1 = 1` | `x` | `x` | match |
| mixed_01 | `SELECT COALESCE(NULL, 'x') \|\| CASE 1 WHEN 1 THEN 'a' ELSE 'b' END` | `xa` | `xa` | match |
| mixed_02 | `SELECT COALESCE(nextval('f5_s7'), 0)` | `3` | `3` | match |
| mixed_03 | `SELECT CASE COALESCE(NULL, 2) WHEN 2 THEN 'two' ELSE 'other' END` | `two` | `two` | match |

## Known gaps

* **Equivalence is shown on these 37 cases, not in general.** `DECODE` compares a search value of another type by Oracle's
  conversion rules and returns the type of its first result; `CASE` follows PostgreSQL's typing, so type mixes that Oracle accepted
  can fail or change type. `DECODE` with a non-literal search value that is NULL at run time is not NULL-matched (only a literal
  `NULL` is). `NVL` evaluates both arguments and `COALESCE` stops at the first non-NULL one.
* `rec.nextval` (a record field called `nextval`) is indistinguishable from a sequence and would be rewritten; `''` is not rewritten
  at all (detection, not rewriting, is F5a's MIG011).
* The unit tests check the text; the PostgreSQL run is the evidence of behavior, and only for the 37 cases.
* Both runs were PostgreSQL 16.15 (Ubuntu and Debian builds); other 16.x or other major versions were not tried.

## Reproduce

```bash
# any PostgreSQL 16 reachable with psql; the variable is the command that reads a script on stdin
export PLSQL_LENS_PSQL='psql -X -q -A -t -v ON_ERROR_STOP=1 -h localhost -U postgres'
PLSQL_LENS_MIGRATE_RESULTS=out/results.json uv run pytest tests/integration/test_migrate_postgres.py -m integration
```

## Spend

I cannot read `/cost` from inside this session, so no figure is reported. No LLM call is made by any code in this change.
