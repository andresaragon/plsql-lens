# Severity by context in MIG011 and MIG002

Contract: [`docs/migration-rules.md`](../migration-rules.md#severity-by-context). Before this change `MIG011` marked every `''` as
`high` and `MIG002` marked every `DECODE` as `low`; the F5c adjudication ([`phase-5.md`](phase-5.md)) showed that one severity per
rule does not tell the serious findings from the benign ones. Now each finding carries its own severity and the rule's severity is the
maximum it can have (`MIG011` high, `MIG002` medium). The number and the location of the findings did not change (the counts in
[`phase-5a.md`](phase-5a.md) are the same; only the severity cell of `MIG002` changed, from `low` to `medium`).

## Rules

| Rule | Context | Severity |
|---|---|---|
| MIG011 | the token before or after the `''` is `\|\|` | `info` |
| MIG011 | the `''` is the whole third argument of `replace(` / `regexp_replace(` (the replacement) | `medium` |
| MIG011 | anywhere else | `high` |
| MIG002 | every search value is a non-null literal (number or string, optional sign) | `low` |
| MIG002 | any search value is a column, an expression, a call or `NULL` | `medium` |

The definitions come from the behavior checked on Oracle 23.26.3 and PostgreSQL 16.15: `'abc' || ''` gives `abc` on both and
`NULL || ''` gives NULL on both; `regexp_replace('abc','b','')` gives `ac` on both, but `regexp_replace('abc','^.*$','')` and
`replace('a','a','')` give NULL on Oracle and `''` on PostgreSQL, so an empty replacement is the same only while the result is not
empty, which cannot be known statically. A `DECODE` whose search values are all non-null literals is exact as a plain `CASE`; any other
search value may be NULL at run time and `DECODE` matches NULL with NULL, also between two columns.

## Counts on `corpus/`

`plsql-lens migrate corpus --format json`, 264 files, 234 findings. Occurrences and files with at least one finding, per rule and
severity (`tests/unit/test_migrate_severity.py` fails if this table stops matching a fresh run):

| Rule | Severity | Occurrences | Files |
|---|---|---|---|
| MIG001 | low | 70 | 21 |
| MIG002 | low | 3 | 3 |
| MIG002 | medium | 8 | 2 |
| MIG003 | medium | 22 | 12 |
| MIG004 | low | 15 | 7 |
| MIG005 | medium | 7 | 6 |
| MIG006 | medium | 2 | 2 |
| MIG007 | medium | 1 | 1 |
| MIG008 | high | 38 | 13 |
| MIG009 | low | 46 | 11 |
| MIG010 | low | 14 | 8 |
| MIG011 | info | 2 | 2 |
| MIG011 | medium | 4 | 2 |
| MIG011 | high | 2 | 1 |

By severity over all rules: 40 `high` (it was 46 when every `''` was `high`), 44 `medium`, 148 `low`, 2 `info`.

Findings at or above a `--fail-on` threshold on the corpus: `MIG011` 8 / 6 / 2 at `info` / `medium` / `high`; `MIG002` 11 / 8 at
`low` / `medium`. `--fail-on high --rules MIG011` exits 1 (two findings in `ut_utils.pkb`); a file whose only `''` is in `x || ''`
passes `--fail-on medium`.

## Agreement with the F5c adjudication

The 19 findings of `MIG011` (all 8) and `MIG002` (all 11) were adjudicated in [`phase-5/adjudication.json`](phase-5/adjudication.json).
Mapping: `benign` → `info`; `semantic-trap` whose note starts with "'' as the replacement" → `medium`; the other `semantic-trap` →
`high`; for `MIG002`, `mechanical` → `low` and `semantic-trap` → `medium`.

| Rule | Adjudication label | Severity assigned by the rule | Findings | Agree |
|---|---|---|---|---|
| MIG011 | benign (`x \|\| ''`) | info | 2 | 2 |
| MIG011 | semantic-trap, `''` as the replacement of `regexp_replace` | medium | 4 | 4 |
| MIG011 | semantic-trap, assignment of `''` | high | 2 | 2 |
| MIG002 | mechanical (literal search values) | low | 3 | 3 |
| MIG002 | semantic-trap (NULL-safe comparison of two columns) | medium | 8 | 8 |

19 of 19 agree; none was adjusted to fit (the rules were written from the contract above, then run).

## Limits

* **This is a consistency check, not an independent test.** There are only 19 findings, the adjudication is Claude's and provisional
  (not reviewed by a person), and the labels came from the same reading of the code that suggested the contexts. The context
  definitions come from the verified Oracle/PostgreSQL behavior, not from these counts; the counts only show that the rules reproduce
  the labels.
* The contexts are token patterns. A `''` inside an expression that cannot be empty (`'x' || ''` is `info`, as it should be) and an
  empty replacement that never empties the string are both `medium`/`info` by shape; whether a `medium` finding is a real behavior
  change depends on data the analysis does not see.
* `MIG002` only looks at the search values: a `DECODE` whose subject is a non-simple expression is `medium` only if a search value
  is not a literal, and its rewrite is skipped on purpose (see `phase-5b.md`).
* The severity of the other rules is unchanged (one per rule); `MIG003` was out of scope.
* Not measured: how often each severity is acted on in real migrations.

## Reproduce

```bash
uv run plsql-lens migrate corpus --rules MIG011,MIG002 --format json | python -c "import json,sys,collections; d=json.load(sys.stdin)['findings']; print(collections.Counter((f['rule_id'], f['severity']) for f in d))"
uv run pytest tests/unit/test_migrate_severity.py
```

## Spend

I cannot read `/cost` from inside this session, so no figure is reported. No LLM call is made by any code in this change.
