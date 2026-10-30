# Migration reference cases (F5)

`semantics.json` holds 37 SQL cases whose results were **observed on a real Oracle**
(`Oracle AI Database 26ai Free Release 23.26.3.0.0`, image `gvenzl/oracle-free:23.26.3-slim-faststart`), not
written by an LLM. A rewrite from `plsql_lens.migrate` must reproduce `oracle_result` when the rewritten SQL
runs on PostgreSQL (checked on 16.15).

* `construct`: `nvl`, `decode`, `nextval`, `from_dual` or `mixed`.
* `setup`: statements that are valid, unchanged, on both databases (they create the case's own sequence).
* `oracle_sql`: a `SELECT` whose single column is the case's result; `oracle_result` is its text (`<NULL>` for NULL;
  Oracle prints NULL and `''` alike because they are the same value there).
* `known_divergence` (5 cases): the mechanical rewrite is correct yet PostgreSQL gives another result for a reason
  outside the rewrite: `oracle_empty_string_is_null` (`''` is NULL on Oracle only) or `oracle_concat_ignores_null`
  (`'abc' || NULL` is `'abc'` on Oracle and NULL on PostgreSQL). `pg_naive_result` is what the plain rewrite gives.

Each case also has a hand-written PostgreSQL translation inside `scripts/migrate_semantics.py`, used only to check
the data set itself (equal results for the other 32 cases, different for the 5). Regenerate with that script and
the two shell-command variables described in its docstring; then update the hash in
`tests/unit/test_migrate_semantics_fixture.py`.
