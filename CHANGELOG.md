# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Each entry below can be traced to the phase report that describes it. The package is not published
to PyPI and nothing has been released yet, so everything is listed under `[Unreleased]` (version
0.1.0 in `pyproject.toml`), without dates.

## [Unreleased]

### Added

#### F1 — Parser and inventory ([report](docs/reports/phase-1.md))

- Tolerant lexer and structural recursive-descent parser written for this project, with no external
  parser dependency, producing a frozen-dataclass IR. The choice among four options is recorded in
  [`docs/adr/0001-parser.md`](docs/adr/0001-parser.md).
- Inventory of units, parameters and resolved call edges, as JSON and as Mermaid (package level by
  default, `--level unit` for subprograms).
- CLI command `plsql-lens inventory PATH --format json|mermaid -o OUT`.
- Corpus of utPLSQL, OraOpenSource Logger and Oracle sample-schema sources (provenance in `NOTICE`)
  and a hand-labeled ground truth used by the acceptance tests.
- Project scaffold: uv, ruff, `mypy --strict` on `src/`, and GitHub Actions CI on Python 3.11 and 3.13.

#### F2 — Review rules ([report](docs/reports/phase-2.md))

- A statement layer in the parser (flat `Stmt` records with their enclosing context), decided in
  [`docs/adr/0002-statement-layer.md`](docs/adr/0002-statement-layer.md).
- Review rules PLL001–PLL007; contract and accepted false negatives in [`docs/rules.md`](docs/rules.md).
- Findings with rule id, severity, location, message, rationale, fix hint and enclosing unit, as a
  plain-text table, JSON or SARIF 2.1.0.
- Inline suppression with `-- plsql-lens: disable=PLLnnn` (trailing comment, next code line, or whole
  subprogram on its header line).
- CLI command `plsql-lens review PATH [--format table|json|sarif] [--rules …] [-o OUT] [--explain …]`.
- Optional LLM explanation layer (`--explain`) with the providers `claude-cli` (default),
  `anthropic-api` and `fake` (recorded responses). It only attaches an explanation and a patch to
  findings that already exist, and reports tokens and cost.
- CI enforces a line-coverage floor of 85 %.

#### F3 — utPLSQL test generation ([report](docs/reports/phase-3.md))

- `plsql-lens testgen PATH --unit PKG.PROC [--run]`: builds a prompt from the unit, its package spec
  and the DDL it touches, asks the LLM for a utPLSQL package, compiles it on Oracle, sends compile
  errors back for a bounded number of repairs, runs it and writes JUnit XML and JSON metrics.
- `plsql-lens testgen-setup` and `testgen-suite` (run the committed tests without an LLM; `--generate`
  and `--repair-from` regenerate or repair them).
- Oracle access through a shell command (`PLSQL_LENS_SQLPLUS`) piping scripts into `sqlplus`, with
  credentials only through environment variables.
- 30 target units with the reason each was chosen, in `tests/fixtures/testgen/manifest.json`.
- A manually triggered GitHub Actions job that runs the committed tests against Oracle Free and
  utPLSQL (`.github/workflows/oracle.yml`).
- SARIF output validated in a test against the official SARIF 2.1.0 JSON Schema (`jsonschema` is a
  development dependency only).

#### F4 — Benchmark ([report](docs/reports/phase-4.md))

- `src/plsql_lens/bench/`: a seeded, deterministic generator of defective and clean PL/SQL with
  expected lines, a scorer, confidence intervals, an engine runner, a report renderer and an LLM-only
  baseline harness.
- CLI commands `plsql-lens bench` and `plsql-lens bench-llm`.
- A sealed `test` split (SHA-256 in `docs/benchmarks/seal.json`, enforced by a unit test) next to a
  `dev` split, with methodology and results in `docs/benchmarks/`.

#### F4b — External-author split ([report](docs/reports/phase-4b.md))

- Frozen reference rules (`docs/benchmarks/external/frozen.json`), enforced by
  `tests/unit/test_external_frozen.py`.
- A converter and evaluator for an externally authored split, with the CLI
  `plsql-lens bench-external convert|run|llm|report`.
- A sealed manifest of the external cases, with a strict and a provisional adjudicated result table.

#### F5a — Oracle→PostgreSQL migration rules ([report](docs/reports/phase-5a.md))

- Contract for eleven token rules, MIG001–MIG011, in [`docs/migration-rules.md`](docs/migration-rules.md): `NVL`, `DECODE`,
  `SYSDATE`/`SYSTIMESTAMP`, `seq.NEXTVAL`/`CURRVAL`, `ROWNUM`, `CONNECT BY`, `(+)`, `PRAGMA AUTONOMOUS_TRANSACTION`,
  `DBMS_OUTPUT`, `FROM DUAL` and the empty string literal `''`.
- Package `plsql_lens.migrate` (`MIGRATION_RULES`, `migrate_file`, `migrate_source`), separate from the review rules, which are
  unchanged.
- CLI command `plsql-lens migrate PATH [--format table|json|sarif] [-o OUT] [--rules …] [--fail-on …]`, with its own SARIF
  writer because the review one indexes the review rules.
- Positive and negative fixtures for every rule, written from the contract only.

#### F5b — Safe rewrite, checked on PostgreSQL ([report](docs/reports/phase-5b.md))

- `plsql_lens.migrate.rewrite.rewrite_sql`: conservative rewrites of `NVL` → `COALESCE`, `DECODE` → `CASE`,
  `seq.NEXTVAL`/`CURRVAL` → `nextval('seq')`/`currval('seq')` and `FROM DUAL` dropped. A construct that cannot be rewritten
  safely is left as it was and listed with its reason; the text outside the rewritten spans is unchanged and a second pass changes nothing.
- 37 reference cases whose results were observed on Oracle Free 23.26.3 (`tests/fixtures/migrate/semantics.json`, with
  `scripts/migrate_semantics.py` to regenerate them), run on PostgreSQL 16 by an integration test through `PLSQL_LENS_PSQL`; five
  cases are labelled as known divergences.
- Manual workflow `postgres.yml`: runs those cases on `postgres:16` and publishes the results to the branch `ci-results/f5`.

### Changed

- Rules tuned on the `dev` split of the benchmark: the PLL004 contract now also exempts `LISTAGG`
  selects, and false positives in PLL006 and PLL007 were removed ([F4 report](docs/reports/phase-4.md)).
