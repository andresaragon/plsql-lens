# PL/SQL Lens

Python library + CLI that analyzes Oracle PL/SQL packages: it inventories units and call graphs, reviews code with
seven deterministic rules, generates and runs utPLSQL tests, and measures the rules on a seeded benchmark.

## Status

Phases F1 to F4b and F5a to F5c are implemented (plan and decisions: [SPEC.md](SPEC.md); one report per phase in
[Reports and further reading](#reports-and-further-reading)):

| Phase | What it delivers | Needs |
|---|---|---|
| F1 | Parser and inventory: units, subprograms, parameters, call graph (JSON, Mermaid) | nothing |
| F2 | Review rules PLL001–PLL007 with table, JSON and SARIF output; optional LLM explanations | nothing (LLM only for `--explain`) |
| F3 | utPLSQL test generation, compile/repair/run on Oracle Free, metrics report | Oracle; an LLM only to generate |
| F4 | Seeded benchmark of the rules (before/after tuning, LLM-only baseline) | nothing (an LLM only for the baseline) |
| F4b | External-author split: a cross-author check of the frozen rules | nothing (an LLM only for the baseline) |
| F5a | Oracle→PostgreSQL migration rules MIG001–MIG011 and `plsql-lens migrate` (detection only) | nothing |
| F5d | Per-finding severity for `MIG011` and `MIG002`, differential fuzzing of the rewrite on Oracle and PostgreSQL, and a pre-publication audit | nothing (Oracle and PostgreSQL for the fuzzing run) |
| F5c | Measurement of the migration rules on `corpus/`: 140 of 234 findings adjudicated by impact, and a `DECODE` rewrite defect it exposed and fixed | nothing |
| F5b | Conservative SQL rewrite (`rewrite_sql`) of `NVL`, `DECODE`, `seq.NEXTVAL` and `FROM DUAL`, checked on PostgreSQL against results observed on Oracle | nothing (PostgreSQL 16 for the integration test) |

## Quick start

```bash
uv sync
uv run plsql-lens inventory corpus/ --format json -o inventory.json
uv run plsql-lens inventory corpus/ --format mermaid -o callgraph.mmd   # --level unit for subprograms
uv run plsql-lens review corpus/logger/logger.pkb                       # table of findings
uv run pytest            # unit + acceptance tests; no Docker, no network needed (the packaging tests skip offline)
make demo-f1             # regenerates docs/reports/phase-1/
```

```python
from plsql_lens import parse_file, build_inventory

ir = parse_file("corpus/logger/logger.pkb")  # IR: units, subprograms, params, call sites
inv = build_inventory(["corpus/logger"])  # units + resolved call edges
```

## Review: findings from the seven rules

`plsql-lens review PATH` parses a file or a directory and reports findings of PLL001–PLL007 (contract, severities
and accepted false negatives: [docs/rules.md](docs/rules.md)). Findings are deterministic functions of the parsed
code; no network or LLM is involved unless you pass `--explain`.

```bash
uv run plsql-lens review corpus/logger/logger.pkb                              # table (default)
uv run plsql-lens review corpus/logger/logger.pkb --format json -o review.json
uv run plsql-lens review corpus/logger/logger.pkb --format sarif -o review.sarif   # SARIF 2.1.0
uv run plsql-lens review corpus/ --rules PLL001,PLL002                         # only these rules
make demo-f2             # the three formats + per-rule counts in docs/reports/phase-2/
```

* `--format table|json|sarif` chooses the output (`table` by default); `-o FILE` writes it to a file instead of stdout.
* `--rules PLL001,PLL002` restricts the run to those rule ids (an unknown id is an error).
* A finding can be suppressed in the source with `-- plsql-lens: disable=PLL007,PLL003` (see *Suppression* in
  [docs/rules.md](docs/rules.md)).
* `--explain` asks an LLM to attach an explanation and a patch suggestion to each finding. It never adds, removes
  or changes findings, and it costs money with a real backend. Choose the backend with `--llm`: `claude-cli`
  (default, runs `claude -p`), `anthropic-api` (needs `ANTHROPIC_API_KEY`) or `fake` (replays `--llm-recordings`,
  free). `--explain-max N` caps how many findings are sent (most severe first, 10 by default).
* `--fail-on never|info|low|medium|high` makes the command exit 1 when a finding has at least that severity
  (`never`, the default, always exits 0). The report is written in full first. Exit codes:
  [docs/cli-exit-codes.md](docs/cli-exit-codes.md).

```bash
uv run plsql-lens review corpus/logger/logger.pkb --explain --format json -o review.json   # calls the LLM
```

Sample output and the SARIF/JSON files: [docs/reports/phase-2/](docs/reports/phase-2/) (as of F2, before the F4 tuning: a
fresh `review` of `corpus/logger/logger.pkb` gives 95 findings, the sample has 101).

## GitHub Action

`action.yml` at the repository root is a composite action: it runs `plsql-lens review`, writes the findings as
SARIF 2.1.0 and, with `fail-on`, fails the step on a severity threshold. It installs the tool from its own checkout
(not published to PyPI) and uploading to code scanning is opt-in (`upload: true`).

```yaml
- uses: andresaragon/plsql-lens@<full-commit-sha>
  with:
    path: db/packages
    fail-on: high
```

Inputs and full workflow examples: [docs/github-action.md](docs/github-action.md). This repository checks the action with
[`action-selftest.yml`](.github/workflows/action-selftest.yml) on pull requests and on pushes to `main`.

## Migration: Oracle → PostgreSQL hints (F5a)

`plsql-lens migrate PATH` reports the Oracle constructs that need attention when PL/SQL moves to PostgreSQL: eleven
deterministic token rules, MIG001–MIG011 (`NVL`, `DECODE`, `SYSDATE`/`SYSTIMESTAMP`, `seq.NEXTVAL`/`CURRVAL`, `ROWNUM`,
`CONNECT BY`, `(+)`, `PRAGMA AUTONOMOUS_TRANSACTION`, `DBMS_OUTPUT`, `FROM DUAL` and the empty string literal `''`, which
is `NULL` in Oracle but not in PostgreSQL). Contract, severities and accepted false positives and negatives:
[docs/migration-rules.md](docs/migration-rules.md). They are separate from the review rules (`review` does not run them),
no LLM is involved, and the command only reports: it does not rewrite code. The mechanical subset (`NVL`, `DECODE`,
`seq.NEXTVAL`/`CURRVAL`, `FROM DUAL`) can be rewritten by the library function `plsql_lens.migrate.rewrite.rewrite_sql` (F5b; it
has no CLI command): it never rewrites halfway, listing what it leaves untouched. Each rewrite is run on PostgreSQL 16 against
42 cases whose results were observed on a real Oracle (`tests/fixtures/migrate/semantics.json`): 37 give the same result and 5 differ
for reasons outside the rewrite (`''` is not `NULL` in PostgreSQL, and `'abc' || NULL` is `NULL` there). That is evidence on those
cases, not a proof of general equivalence: [docs/reports/phase-5b.md](docs/reports/phase-5b.md). Adjudicating the findings on `corpus/`
(140 of 234, by impact) also exposed a `DECODE` rewrite defect that is now fixed, and showed that only 2 of the 8 `''` findings
are strictly benign (a concatenation), the other 6 being traps: [docs/reports/phase-5.md](docs/reports/phase-5.md).

```bash
uv run plsql-lens migrate corpus/logger/logger.pkb                          # table of findings
uv run plsql-lens migrate corpus/ --format sarif -o migrate.sarif           # SARIF 2.1.0
uv run plsql-lens migrate corpus/ --rules MIG008,MIG011 --fail-on high      # only these rules; exit 1 on a high finding
```

`--format`, `-o`, `--rules` and `--fail-on` work as in `review` (exit codes: [docs/cli-exit-codes.md](docs/cli-exit-codes.md)),
and `-- plsql-lens: disable=MIG001` suppresses a finding in the source. On `corpus/` it reports 234 findings in 42 of 264
files; counts per rule and what they do not mean: [docs/reports/phase-5a.md](docs/reports/phase-5a.md).

Severity is per finding: `MIG011` is `info` next to `||`, `medium` as the replacement of `replace`/`regexp_replace` and `high`
otherwise, and `MIG002` is `medium` when a search value may be `NULL` and `low` when all are literals, so `--fail-on high` stops
on the real traps only ([docs/reports/migrate-severity.md](docs/reports/migrate-severity.md); on `corpus/`: 2 `info`, 4 `medium`
and 2 `high` for `MIG011`). A differential run of 977 generated integer `NVL`/`DECODE` statements gave the same result on
Oracle 23.26.3 and PostgreSQL 16.15, with 0 discrepancies and a control that does detect the naive `CASE` rewrite; the other
1023 of the 2000 generated statements are skipped by the rewrite on purpose and were not run
([docs/reports/migrate-differential.md](docs/reports/migrate-differential.md)).

## Commands

| Command | What it does | Needs |
|---|---|---|
| `plsql-lens inventory PATH` | Units, subprograms and resolved call graph; `--format json\|mermaid`, `--level package\|unit` | nothing |
| `plsql-lens review PATH` | Review rules PLL001–PLL007; `--format table\|json\|sarif`, `--rules`, `--explain`, `--fail-on` | nothing (LLM only with `--explain`) |
| `plsql-lens testgen PATH --unit U` | Generates a utPLSQL test package for one unit; `--run` compiles, repairs and runs it | LLM (costs money); Oracle for `--run` |
| `plsql-lens testgen-setup` | Installs the target objects (Logger, HR, test packages) into the configured Oracle schema | Oracle |
| `plsql-lens testgen-suite` | Runs the committed tests and writes `report.json` / `junit.xml`; `--generate` regenerates them | Oracle; LLM only with `--generate` (costs money) |
| `plsql-lens migrate PATH` | Oracle→PostgreSQL migration rules MIG001–MIG011; `--format table\|json\|sarif`, `--rules`, `--fail-on` | nothing |
| `plsql-lens bench` | Regenerates the benchmark splits, runs the before/after rules, scores and writes `results.md` | nothing |
| `plsql-lens bench-llm` | LLM-only baseline on a seeded sample of the `test` split, capped with `--max-usd` | LLM (costs money) |
| `plsql-lens bench-external` | Evaluation on the external-author split: `convert`, `run`, `run-before`, `llm`, `report` | nothing; `llm` costs money |

Run `uv run plsql-lens COMMAND --help` for every option. Commands that cost money say so in their help text.

## Parser and inventory (F1)

* Tolerant lexer + structural recursive-descent parser (no external parser dependency); it reports structural
  problems in `FileIR.issues` and did not raise on any of 2400 seeded mutations of the corpus. Five inputs of extreme repetition
  do break "never raises, quickly" (one `RecursionError`, four slow cases): [docs/reports/robustness.md](docs/reports/robustness.md).
* Inventory of packages, standalone procedures/functions, triggers and types, with parameters and a
  resolved call graph; JSON and Mermaid output.
* Measured results: [docs/reports/phase-1.md](docs/reports/phase-1.md); parser decision:
  [docs/adr/0001-parser.md](docs/adr/0001-parser.md).

## F3: generated utPLSQL tests (needs Oracle)

```bash
make help
make demo-f3      # runs the committed generated tests on Oracle (Docker, or GitHub Actions) — no LLM calls
make testgen-f3   # regenerates them with the LLM — costs money
uv run plsql-lens testgen corpus/logger/logger.pkb --unit logger.sprintf --manifest tests/fixtures/testgen/manifest.json
```

Oracle Database Free is pulled from Docker Hub (`gvenzl/oracle-free`) under Oracle's own license terms; this
repository does not redistribute it. Passwords come from the environment only (`.env.example`). See
`docker/README.md` and `docs/reports/phase-3.md`.

## Benchmark

[docs/benchmarks/](docs/benchmarks/) measures the seven review rules on a frozen, seeded `test` split
(350 seeded defects and 350 hard negatives, 7 rules, 105 files; methodology, matching definition and threats to
validity are in its README). On `test`, the tuned rules reach precision 1.000 [0.99–1.00] and recall 0.998
[0.99–1.00] (464 TP / 0 FP / 1 FN); the rules before tuning score the same, and the LLM-only baseline on a
40-file sample costs 1.13 USD. Read the threats-to-validity section before quoting these: the benchmark checks
the rules against their own contract, not against defects found in the wild. `make bench` regenerates everything
without calling an LLM.

The external-author split ([docs/benchmarks/external/](docs/benchmarks/external/), F4b) is a cross-author check with 40
cases written by another LLM (Gemini), not by a human: the frozen rules and an LLM-only baseline both score 64 TP / 2 FP / 0 FN (strict; adjudicated
provisionally 65 / 1 / 0), and 0 of 9 real-world (`beyond`) defects outside the contract. Same caveats apply.

## Reports and further reading

* Plan and decisions: [SPEC.md](SPEC.md). Review-rule contract: [docs/rules.md](docs/rules.md). Migration-rule contract: [docs/migration-rules.md](docs/migration-rules.md).
* Phase reports: [F1](docs/reports/phase-1.md) · [F2](docs/reports/phase-2.md) · [F3](docs/reports/phase-3.md) ·
  [F4](docs/reports/phase-4.md) · [F4b](docs/reports/phase-4b.md) · [F5a](docs/reports/phase-5a.md) · [F5b](docs/reports/phase-5b.md) · [F5c](docs/reports/phase-5.md) · [robustness](docs/reports/robustness.md) · [pre-publication audit](docs/reports/prepublication-audit.md).
* Benchmark: [methodology](docs/benchmarks/README.md) · [results](docs/benchmarks/results.md) ·
  [external-author split](docs/benchmarks/external/README.md) ([results](docs/benchmarks/external/results.md)).
* Design decisions: [ADR 0001 (parser)](docs/adr/0001-parser.md) ·
  [ADR 0002 (statement layer)](docs/adr/0002-statement-layer.md).

Third-party PL/SQL used as test input lives in `corpus/` and is listed in [NOTICE](NOTICE).
License: MIT.
