# Phase F5a report — Oracle→PostgreSQL migration rules

Branch `feat/f5-migrate-rules`, one draft PR on `main` @ `4aaacb1`. Contract: [`docs/migration-rules.md`](../migration-rules.md).

## What was built

* **Contract first** (`docs/migration-rules.md`): rules MIG001–MIG011, their severities and locations, how they read the token
  stream of the whole file, the accepted false negatives and the command. It was committed before any code or fixture.
* **`plsql_lens.migrate`**: `MIGRATION_RULES` (a `dict[str, Rule]`, separate from `rules.RULES`), `migrate_source(src, path, rules)`
  and `migrate_file(path, rules)`. Findings reuse `Finding`/`Location`/`Rule`; the enclosing unit is filled from the IR by line
  range and inline `-- plsql-lens: disable=MIGnnn` suppression reuses `rules.suppress.apply_suppressions`.
* **`migrate/output.py`**: its own `to_sarif` (the review one indexes `RULES`); the table and JSON writers are the review ones.
* **`plsql-lens migrate PATH [--format table|json|sarif] [-o OUT] [--rules …] [--fail-on …]`**: same semantics and exit codes
  as `review` ([`cli-exit-codes.md`](../cli-exit-codes.md)). It is the only change in `cli.py`.
* **Fixtures** `tests/fixtures/migrate/rules/MIGnnn/{pos,neg}_{1,2,3}.pkb` (33 positive, 33 negative), written from the contract
  only, with `-- expect: MIGnnn` markers. Negatives are near misses: the construct inside a string or a comment, after a `.`,
  as part of a longer identifier, or a different construct (`nvl2`, `current_date`, `LEFT JOIN`, …).
* Tests were committed red first (collection error: no `plsql_lens.migrate`), in their own commit after the contract.

## Acceptance

| Criterion | Result |
|---|---|
| Each `pos_N` yields exactly the marked lines, no `neg_N` yields a finding of its rule | 66 fixtures, all as marked (`tests/unit/test_migrate_rules.py`) |
| `RULES` is still exactly PLL001–PLL007, `review` unchanged | yes; `test_cli_review.py` (output hashes) and `test_external_frozen.py` pass untouched; `migrate` registers nothing in `RULES` |
| `migrate corpus/` does not raise, < 60 s | no error; about 0.8 s wall clock |
| SARIF validates against `tests/vendor/sarif-2.1.0.json`; `disable=MIG001` suppresses | yes (`tests/unit/test_migrate_cli.py`, `test_migrate_rules.py`) |

## Counts on `corpus/`

`plsql-lens migrate corpus --format json`: 264 PL/SQL files scanned, 234 findings in 42 of them. Occurrences (one finding per
token match) and files with at least one finding, per rule. They are not interpreted here; `tests/unit/test_migrate_report.py`
fails if this table stops matching a fresh run.

| Rule | Severity | Occurrences | Files |
|---|---|---|---|
| MIG001 | low | 70 | 21 |
| MIG002 | low | 11 | 5 |
| MIG003 | medium | 22 | 12 |
| MIG004 | low | 15 | 7 |
| MIG005 | medium | 7 | 6 |
| MIG006 | medium | 2 | 2 |
| MIG007 | medium | 1 | 1 |
| MIG008 | high | 38 | 13 |
| MIG009 | low | 46 | 11 |
| MIG010 | low | 14 | 8 |
| MIG011 | high | 8 | 4 |

These are token counts: comments, strings and quoted text do not count, so they are not comparable with a plain text search.

## Known gaps

* No finding was adjudicated here (precision on real code is F5c, local).
* The rules are token matches without semantics; the accepted false negatives and positives are in the contract.
* The fixtures check the contract, not that the Oracle constructs behave as described; that is what F5b's reference cases are for.

## Spend

I cannot read `/cost` from inside this session, so no figure is reported. No LLM call is made by any code in this change.
