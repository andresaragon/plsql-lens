# Phase F1 report — Parser & inventory

Date: 2026-10-22. Branch `feat/f1-parser-inventory`.

## What was built
* Scaffold: uv, ruff, `mypy --strict` on `src/`, GitHub Actions CI (lint + types + tests on Python 3.11 and 3.13).
* Corpus (264 files, 29.5 KLOC, provenance in `NOTICE`): utPLSQL (Apache-2.0), OraOpenSource Logger (MIT),
  Oracle db-sample-schemas (MIT).
* Hand-labeled ground truth (`tests/acceptance/ground_truth*/`): 169 units, 171 call edges, 117 parameters
  over 14 files. Labeled by Sonnet subagents reading the source, spot-checked by the lead; labeling
  conventions are in the ADR/this report (kinds collapse per overload name, nested subprograms excluded).
* Parser (option D, `src/plsql_lens/parser/`): tolerant lexer + structural recursive-descent parser → frozen-dataclass IR.
* Inventory (`src/plsql_lens/inventory/`): units, parameters, resolved call edges; JSON and Mermaid
  (package level by default, `--level unit` for subprograms).
* CLI: `plsql-lens inventory PATH --format json|mermaid -o OUT`.
* TDD order in git history: scaffold → acceptance tests (red, collection error) → implementation (green).

## Spike (full table and caveats: `docs/adr/0001-parser.md`)
| Option | Parse success | ms/KLOC | Inventory vs ground truth |
|---|---|---|---|
| A ANTLR4 grammars-v4 | 90.9 % (33-file sample) | 27 958 | partial; 8/57 units on logger.pkb |
| B tree-sitter `sql` | 0 % error-free | 14.9 | n/a |
| C sqlglot (Oracle) | 42.8 % no exception, 0 structured | 16.2 | n/a |
| **D hand-written** | **100 %** (264/264) | **9.4** | units F1 1.000, edges 0.98–0.99 |

Decision: D. Details and rejected options in the ADR.

## Acceptance (SPEC §3 F1) — measured, targets unchanged
| Criterion | Target | Measured |
|---|---|---|
| Corpus files parsed without fatal/structural error | ≥ 95 % | **100 %** (264/264) |
| Units F1 — logger+hr / utPLSQL core | ≥ 0.95 | **1.000 / 1.000** |
| Call-edge F1 — logger+hr / utPLSQL core | ≥ 0.90 | **0.982 / 0.994** (P 0.966/0.989, R 1.000/1.000) |
| Parameter F1 (logger.pks, not in SPEC) | — | 1.000 (117/117) |
| Mermaid renders | yes | package-level graph (150 edges) rendered to SVG with `@mermaid-js/mermaid-cli` 11.4.2 + Chromium; structural check in the test suite |

Tests: 17 pass (6 acceptance, 11 unit), 93 % line coverage, ruff/mypy clean. Reproduce scores:
`uv run python scripts/score_ground_truth.py -v`.

## Known gaps
* The parse rate comes from the corpus the parser was developed against (two lexer bugs were fixed from
  corpus failures); it is not a held-out measurement. The ground truth was not used for tuning.
* 4 false-positive edges, all calls to parameterless functions inside expressions
  (`then include_call_stack`, `ut_owner` in a package-level initializer). The labeling convention only
  counted `name(...)`/`name;`; these look like real calls the labels omitted. Left as is.
* Calls are resolved by name only: no types, no `schema.pkg` disambiguation beyond the last two parts,
  overloads (and same-name function/procedure pairs) collapse into one unit keyed by the first declared kind.
* Both branches of `$if ... $then` are kept as code. Compound triggers and type-member bodies of
  triggers are inventoried as units only (no per-section calls). Dynamic SQL strings are not analyzed.
* Spike A was sampled (33 files), not run on the full corpus; B/C are single timings and have no inventory.
* The labeled set is 14 files; most of the corpus (type bodies, reporters) has no ground truth,
  only the parse-rate check.

## Demo
```bash
make demo-f1     # regenerates docs/reports/phase-1/{inventory.json,callgraph.mmd,callgraph.md}
```

## Spend
Budget 9 USD (estimate 8–11). **I cannot read `/cost` from inside this session**, so the figure below
is a rough estimate from token usage, not a measurement: lead ≈ 3–4 USD plus three Sonnet labeling
subagent runs (≈ 0.9 + 0.8 + 0.2 USD) → **≈ 5–6 USD, within budget; the reserve was not touched.**
Please check `/cost` and correct this line.
