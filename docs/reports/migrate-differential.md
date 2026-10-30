# Differential fuzzing of `rewrite_sql` on Oracle and PostgreSQL

F5-G1. F5c found, by reading real code, that `DECODE(a, b, 1, 0)` with `a` and `b` NULL is `1` on Oracle and was `0` after the
rewrite ([phase-5.md](phase-5.md)): the 42 hand-written reference cases could not have shown it. This report is the answer to
"what else is there?": random statements, original on Oracle and rewritten on PostgreSQL, compared by result.

**Result: 977 statements executed, 977 gave the same result on both databases, 0 discrepancies, 0 errors on either side.** A
positive control (the known-naive rewrite of the F5c defect) was seen to differ, so the empty list is not a harness that sees nothing.
Zero discrepancies is a result of this run on this generator, not a proof of equivalence: see *Limits*.

## Method

* **Generator** (`tests/differential/fuzzgen.py`, a pure function of the seed): `SELECT <expr> FROM (SELECT CAST(NULL AS INTEGER) n1,
  CAST(NULL AS INTEGER) n2, 1 v1, 2 v2, 2 v3, 7 v4 FROM DUAL)` where `<expr>` is an INTEGER expression of at most three nested calls
  of `NVL(e, e)`, `DECODE(e, s1, r1 [, s2, r2 [, s3, r3]] [, default])` and an occasional `e + 1`. Operands are the six columns, the
  digits 0-9 and `CAST(NULL AS INTEGER)`; a bare `NULL` appears only as a literal `DECODE` search value. No strings, no `''`, no
  `||`, no mixed types: those differences are already known (`''` is NULL on Oracle, `'abc' || NULL`, `COALESCE(text, integer)`) and
  would only add noise. The statements are distinct and the same seed gives the same list (unit tests, no database).
* **Rewrite**: each statement goes through `rewrite_sql`. A statement is run only if nothing was skipped. The rewrite skips, on
  purpose, a `DECODE` whose search value may be NULL when its subject is not simple (a call, a sequence, a subquery), because the
  NULL-safe form would evaluate the subject more than once; that design decision was not changed.
* **Executor** (`scripts/migrate_differential.py`): one script per database (`PLSQL_LENS_SQLPLUS`, `PLSQL_LENS_PSQL`), results matched
  by statement id. Oracle prints NULL as an empty line (compared as `<NULL>`); PostgreSQL wraps the statement in
  `select coalesce(cast(x as text), '<NULL>') from (<statement>) t(x)`, as in `scripts/migrate_semantics.py`.
* **Control**: the executor also runs `DECODE(n1, n2, 1, 0)` on Oracle against the naive `CASE n1 WHEN n2 THEN 1 ELSE 0 END` on
  PostgreSQL and fails the run (exit 3) if the difference is not seen.
* **CI** (`.github/workflows/differential.yml`): Oracle Free (`docker/compose.yml`) and `postgres:16`, throw-away masked passwords, 40
  minute limit; results are published to the branch `ci-results/f5-differential`.

## The run

| | |
|---|---|
| Workflow run | `differential` run 41125737138 on commit `64224b1` (results: branch `ci-results/f5-differential`, files `results.json`, `run.log`, `versions.txt`, `commit.txt`) |
| Oracle | Oracle AI Database 26ai Free Release 23.26.3.0.0 |
| PostgreSQL | 16.15 (Debian 16.15-1.pgdg13+2), image `postgres:16` |
| Seed | 20261030 (the default; `n` and the seed are inputs of the workflow) |
| N | 2000 |

| Result | Statements |
|---|---|
| Statements generated | 2000 |
| Skipped by the rewrite (not run) | 1023 |
| Fully rewritable and executed | 977 |
| Errors on Oracle | 0 |
| Errors on PostgreSQL | 0 |
| Same result on both databases | 977 |
| Discrepancies | 0 |

Share fully rewritable: 48.9 %.

**Skipped, and why.** All 1023 skipped statements have the same reason, *NULL-able search value on a non-simple expression
(evaluated twice)* (1801 constructs in total, because one statement can contain several). The skipped statements are mostly the
deepest ones (calls nested 1 / 2 / 3 deep: 38 / 221 / 764), so the executed sample leans shallow: 484 / 290 / 203.

**Control.** `DECODE(n1, n2, 1, 0)` gave `1` on Oracle and the naive `CASE n1 WHEN n2 THEN 1 ELSE 0 END` gave `0` on PostgreSQL: the
difference was detected on the real databases.

**The comparison is not trivial.** Distribution of the matched values: `<NULL>` 293, 2: 186, 1: 107, 7: 103, 3: 47, 4: 44, 6: 41,
8: 40, 5: 39, 9: 37, 0: 30, 10: 9, 11: 1. Of the 977 executed statements (counted from the rewrites, which depend only on the seed and
the code), 537 use the NULL-safe `IS NOT DISTINCT FROM` form added after F5c, 229 the `IS NULL` form, 230 the plain `CASE x WHEN lit`
form, 638 contain `COALESCE`, and 381 have an `NVL` inside a `DECODE` statement. They hold 1170 `DECODE` calls.

**Discrepancies explained.** None to explain. The shortest discrepancy the harness can show is the control above, which is the F5c
defect. A first run before the control and the value distribution were added (run 41124699848, commit `e422918`) had the same counts:
977 executed, 977 matches, 0 errors.

## Limits

* The fuzzer covers `NVL` and `DECODE` over integers only, depth at most 3, over one fixed row (`n1`, `n2` always NULL; `v1`…`v4`
  always 1, 2, 2, 7). Whether a column is NULL never varies between runs, so combinations such as "this column NULL in one row and not in
  another" are not exercised; they are exercised here only through the two NULL columns and the NULL literals.
* The skipped class (NULL-able search value over a non-simple subject, 51 % of the statements) is never executed: it is a design decision
  of the rewrite, and the differential run says nothing about it.
* Strings, `''`, `||`, dates, sequences and `FROM DUAL` in other shapes are out of scope, as are all other rewrites.
* One seed and one N. Other seeds could find something; the workflow takes both as inputs (`n` up to 5000).
* This is evidence of correspondence on these statements, on these two engine versions, not a proof of equivalence.

## Reproduce

```bash
uv run pytest tests/differential                    # no database: generator, rewrite checks, executor with fakes, this report's counts
PLSQL_LENS_SQLPLUS='docker exec -i <oracle> sqlplus -s -L system/<pw>@//localhost/FREEPDB1' \
PLSQL_LENS_PSQL='docker exec -i <postgres> psql -X -q -A -t -U postgres' \
uv run python scripts/migrate_differential.py --seed 20261030 --n 2000 --out out/differential
```

or run the `differential` workflow from the Actions tab.

## Spend

I cannot read `/cost` from inside this session, so no figure is reported. No LLM call is made by any code in this change.
