# Phase F5c report — measuring the migration rules on `corpus/`

Branch `feat/f5c-measurement`, one draft PR on `main` @ `ce62af8`. F5c runs locally (no cloud credit) on top of F5a
([report](phase-5a.md)) and F5b ([report](phase-5b.md)). The adjudication data is in
[`phase-5/adjudication.json`](phase-5/adjudication.json); the table below is `python scripts/migrate_adjudication.py`.

## Headline

* **Adjudicating the findings exposed a defect in the F5b rewrite, which is fixed here.** 8 of the 11 `DECODE` uses in the corpus
  compare two columns, `decode(a.x, e.x, 1, 0)`. Oracle's `DECODE` treats `NULL = NULL` as a match; the rewrite produced
  `CASE a.x WHEN e.x …`, which does not. On real databases, with both values NULL, Oracle gives 1, the old rewrite gave 0 on
  PostgreSQL, and `a IS NOT DISTINCT FROM b` gives 1. None of the 37 original reference cases could show it because they only
  used literals. Details below.
* **All 140 adjudicated findings are true positives** (the token is the Oracle construct the rule names). That number is close to
  automatic for token rules and says little; what the adjudication adds is the **impact** column: 86 are mechanical, 33 need a manual
  restructure, 19 are semantic traps (a direct translation changes behavior) and 2 are benign.
* **`MIG011` (`''`, severity `high`): only 2 of its 8 findings are strictly benign** (`x || ''`). Four are `''` as a
  `regexp_replace` replacement, which behaves the same unless the replacement empties the whole string (then Oracle returns `NULL`
  and PostgreSQL `''`), and 2 assign `''` to a variable that is then tested with `IS NULL`. *(Corrected on 2026-10-30: this first
  said 6 of 8 were benign; see "Correction".)*
* **22 Oracle constructs sit inside string literals (dynamic SQL) and no rule sees them**, against 234 findings.

## Method

`plsql-lens migrate corpus` reports 234 findings in 42 of 264 files ([phase-5a](phase-5a.md)). Every finding of the rules with few
findings was adjudicated (MIG002–MIG007, MIG010, MIG011: 80 findings). The three large rules (MIG001, MIG008, MIG009) were sampled:
20 each, drawn with `random.Random(20261030).sample` from the findings sorted by file, line and column. Total: 140 of 234.

For each finding the source line and its neighbours were read and two things recorded:

* **verdict** — `tp` if the token is the Oracle construct the rule names, `fp` if it is something else;
* **impact** — `mechanical` (a direct equivalent exists and behaves the same), `needs-rewrite` (no direct equivalent), `semantic-trap`
  (a direct or naive translation changes behavior in this usage) or `benign` (the token matched but behavior is the same).

`tests/unit/test_migrate_adjudication.py` fails if the adjudicated set stops being exactly what a fresh run selects.

## Results

| Rule | Findings | Adjudicated | How | True positives | Wilson 95 % lower (sampled only) | mechanical | needs-rewrite | semantic-trap | benign |
|---|---|---|---|---|---|---|---|---|---|
| MIG001 | 70 | 20 | sample | 20/20 | 0.84 | 19 | 0 | 1 | 0 |
| MIG002 | 11 | 11 | all | 11/11 | complete | 3 | 0 | 8 | 0 |
| MIG003 | 22 | 22 | all | 22/22 | complete | 19 | 0 | 3 | 0 |
| MIG004 | 15 | 15 | all | 15/15 | complete | 15 | 0 | 0 | 0 |
| MIG005 | 7 | 7 | all | 7/7 | complete | 0 | 7 | 0 | 0 |
| MIG006 | 2 | 2 | all | 2/2 | complete | 0 | 2 | 0 | 0 |
| MIG007 | 1 | 1 | all | 1/1 | complete | 0 | 1 | 0 | 0 |
| MIG008 | 38 | 20 | sample | 20/20 | 0.84 | 0 | 20 | 0 | 0 |
| MIG009 | 46 | 20 | sample | 20/20 | 0.84 | 18 | 1 | 1 | 0 |
| MIG010 | 14 | 14 | all | 14/14 | complete | 12 | 2 | 0 | 0 |
| MIG011 | 8 | 8 | all | 8/8 | complete | 0 | 0 | 6 | 2 |
| **All** | 234 | 140 | | 140/140 | | 86 | 33 | 19 | 2 |

The totals mix complete rules and samples, so they are not an estimate for the 234. The Wilson bound is given only for the sampled
rules; the others were adjudicated completely and have no sampling uncertainty.

What the impact column says rule by rule:

* **MIG002** (`DECODE`): 8 of 11 are the NULL-safe comparison of two columns (the trap above); the other 3 compare with literals.
* **MIG003** (`SYSDATE`/`SYSTIMESTAMP`): 3 of 22 are date arithmetic that differs on PostgreSQL (`sysdate + n`, `sysdate - n`,
  `sysdate - date`); the others are plain values.
* **MIG011** (`''`): 2 benign (`|| ''`), 4 conditional traps (a replacement that may empty the string) and 2 traps (assignments).
* **MIG001** (`NVL`): 1 of the 20 sampled is a type trap: `nvl(number_parameter, varchar2_function())` in `logger.purge`. Oracle
  converts the second argument; `COALESCE(numeric, text)` is an error on PostgreSQL. Types are not resolved by the rules, so the
  19 "mechanical" ones assume same-typed arguments; only the suspicious ones were checked in the source.
* **MIG009** (`DBMS_OUTPUT`): `put_line` is mechanical (`RAISE NOTICE`); `get_line` has no equivalent and `put` writes no newline.
* **MIG005, MIG006, MIG007, MIG008**: always a manual restructure (`LIMIT`/`row_number()`, `generate_series`/recursive query,
  `LEFT JOIN`, no equivalent for autonomous transactions).

## What the rules do not see

Constructs inside string literals are never matched (the contract says so). Counting them in the corpus with the lexer, text inside
string tokens:

| Construct | Occurrences | Files |
|---|---|---|
| `nvl(` | 12 | 1 |
| `rownum` | 4 | 3 |
| `from dual` | 3 | 3 |
| `decode(` | 2 | 1 |
| `dbms_output.` | 1 | 1 |
| `sysdate`, `nextval`, `connect by`, `(+)` | 0 | 0 |

That is 22 occurrences in dynamic SQL, against 234 findings. These counts are text matches inside strings, so some may be examples or
messages and not executed SQL; they were not adjudicated.

## A defect in the F5b rewrite, found and fixed

Reading the 11 `MIG002` findings showed that 8 are `decode(a.element_value, e.element_value, 1, 0)` and similar: a NULL-safe equality
written with `DECODE`. `rewrite_sql` turned them into `CASE a.x WHEN e.x THEN 1 ELSE 0 END`, which is only right when every search
value is a non-NULL literal. It was checked on real databases (Oracle Free 23.26.3 and PostgreSQL 16.15, two columns cast from literals):

| `a` | `b` | Oracle `DECODE(a, b, 1, 0)` | PostgreSQL, old rewrite `CASE a WHEN b …` | PostgreSQL `a IS NOT DISTINCT FROM b` |
|---|---|---|---|---|
| NULL | NULL | **1** | **0** | 1 |
| NULL | 5 | 0 | 0 | 0 |
| 5 | NULL | 0 | 0 | 0 |
| 3 | 3 | 1 | 1 | 1 |
| 3 | 4 | 0 | 0 | 0 |

The F5b claim that the rewrite "never rewrites wrongly" held on the 37 reference cases but not on this usage, and the cases could
not have caught it. Fix (`src/plsql_lens/migrate/rewrite.py`):

* `CASE x WHEN lit …` stays when every search value is a non-NULL string or number literal (a NULL subject matches none on either
  database);
* any other search value (a column, an expression) is compared with `x IS NOT DISTINCT FROM s`, which reproduces DECODE's NULL match;
* that form evaluates the subject once per search value, so a non-simple subject (a call, a sequence, a subquery) is now **skipped
  with a reason** instead of rewritten;
* a dotted name (`a.x`) is one operand and gets no parentheses.

Evidence: five new reference cases observed on Oracle (`decode_13`–`decode_17`: both NULL, one NULL, equal, and a mixed form) bring
the set to **42 cases**. Before the fix the PostgreSQL integration test failed on `decode_13` and `decode_17`; after it all 42 pass:
37 give the Oracle result and 5 differ as documented (`''` is not NULL on PostgreSQL; `'abc' || NULL` is NULL there). The red
tests and the fix are separate commits.

## Correction (2026-10-30): the `''` replacement is not benign

The first version of this report labelled four `''` findings (`regexp_replace(…, '', …)`) as benign and headlined "6 of 8 are benign".
That was too strong. In Oracle a function that returns an empty string returns `NULL`; PostgreSQL returns `''`. Checked on Oracle
23.26.3 and PostgreSQL 16.15 (the same engines as above):

| Expression | Oracle | PostgreSQL |
|---|---|---|
| `regexp_replace('abc','b','')` | `ac` | `ac` |
| `regexp_replace('abc','^.*$','')` | NULL | `''` |
| `replace('a','a','')` | NULL | `''` |
| `'abc' \|\| ''` | `abc` | `abc` |
| `NULL \|\| ''` | NULL | NULL |

So a `''` replacement behaves the same only while the result is not empty, which cannot be known statically; those four findings are
now `semantic-trap` (conditional), and only the two `|| ''` findings stay `benign`. The adjudication file and the totals above carry
the correction.

## Limits

* **The adjudicator is Claude**, in the same model family that wrote the rules in a cloud session. The labels are provisional and
  have not been reviewed by a person.
* A true positive is almost definitional for a rule that matches a token. This is not a measure of how often a migration finding
  matters; the impact column is closer to that and is a judgment.
* No type resolution: whether `NVL` or `COALESCE` arguments have compatible types was checked only where it looked suspicious.
* Samples are 20 per large rule; the 0.84 bound is a lower bound for the token being the construct, not for the impact split.
* Recall on real code was not measured except for the string-literal count above.
* The 42 reference cases are evidence of correspondence on those cases, not a proof of equivalence.

## Not verified

* Other PostgreSQL versions than 16.15 and other Oracle versions than 23.26.3.
* Whether the 22 constructs in strings are executed SQL.
* No spend is reported: this phase ran locally and the code calls no LLM.

## What this suggests (not done here)

* `MIG011` could split by context instead of flagging every `''` as `high`: only a concatenation operand (`x || ''`) is strictly
  benign; a function argument can matter (`nvl(x, '')`, a replacement that empties the string).
* The `MIG002` message could warn when a search value is not a literal.
* `rewrite_sql` could look inside string literals that contain SQL, which is today an accepted false negative.

## Reproduce

```bash
uv run plsql-lens migrate corpus --format json -o migrate.json        # the 234 findings
uv run python scripts/migrate_adjudication.py                          # the table above
uv run pytest tests/unit/test_migrate_adjudication.py                  # the adjudicated set is the selected one
```

The Oracle and PostgreSQL results come from `scripts/migrate_semantics.py` and the integration test of
[phase-5b](phase-5b.md).
