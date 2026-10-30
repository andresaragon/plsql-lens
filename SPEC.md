# SPEC — PL/SQL Lens (working name)

> Status: **DRAFT — awaiting approval.** No code is written until this spec and the phase plan are approved.

## 1. Objective

PL/SQL Lens is an open-source **Python library + CLI** that analyzes Oracle PL/SQL packages:

1. builds an **inventory** (packages, procedures, functions, dependencies, call graph),
2. flags **anti-patterns** with deterministic rules (an LLM only *explains* and *proposes fixes*),
3. **generates utPLSQL tests** with Claude and *runs them* against a real Oracle instance in Docker,
4. publishes a **reproducible benchmark** (precision / recall per rule) on a seeded-defect corpus.

**Target users:** PL/SQL developers and tech leads reviewing legacy packages; reviewers of the
author's portfolio (Oracle Senior / AI Engineer roles).

**Success = every claim in the README is backed by a command anyone can rerun** (demo + measured report per phase).

### Non-goals
- Not a full PL/SQL compiler or semantic analyzer (no type resolution across schemas beyond what the source shows).
- Not a SQL formatter or a replacement for Oracle's PL/Scope.
- No connection to any real customer/employer database. Ever.

## 2. Capability map (Phase 0)

| ID | Module | Depends on | Independently testable by |
|----|--------|-----------|---------------------------|
| M1 | `parser` — source → normalized AST/IR (units, params, statements, call sites, embedded SQL) | — | golden IR snapshots on fixture files |
| M2 | `inventory` + `graph` — IR → inventory JSON + Mermaid call graph | M1 | inventory/graph snapshots vs hand-labeled ground truth |
| M3 | `rules` — IR → findings (rule id, severity, location, explanation) | M1 | one positive + one negative fixture per rule |
| M4 | `llm` — explanation/fix proposals for findings (Claude API, optional) | M3 | recorded responses (no network in unit tests) |
| M5 | `testgen` — IR → utPLSQL test packages via Claude; runner against Oracle Docker | M1, M4 client | unit: prompt/packaging with fakes; integration: compile+run in container |
| M6 | `bench` — seeded-defect corpus generator + scorer → `docs/benchmarks/` | M1, M3 | scorer unit tests on tiny labeled corpus |
| M7 | `cli` — thin `plsql-lens` command over M2–M6 | all | CLI tests with `CliRunner` |
| M8 | `migrate` — Oracle→PostgreSQL migration hints and safe rewrites (F5, approved 2026-10-30) | M1 (lexer, IR) | pos/neg fixtures per rule; rewrites checked on PostgreSQL against results observed on Oracle |

Dependency direction is strictly downward (M1 ← everything). No module imports `cli`.
Build order = phase order below.

## 3. Phase plan and budget

Credits: **69 USD** of Claude Code credits, expiring **2026-11-05** (14 days from 2026-10-22).
Opus for SPEC and design decisions only; Sonnet for the rest of the lead's work; mechanical work
delegated to Claude Code subagents (cloud sessions cannot run `/orquestador:*`, see below).

| Phase | Budget | Lead's estimate | Main cost driver / risk | Demo at end of phase |
|-------|--------|-----------------|-------------------------|----------------------|
| SPEC  | 6  | 4–6   | this document | — |
| F1 Parser & inventory | 9  | 8–11  | parser spike (4 options measured); grammar size if ANTLR | `plsql-lens inventory corpus/` → JSON + Mermaid |
| F2 Review rules | 12 | 10–13 | 7 rules × pos/neg fixtures; LLM explanation layer | `plsql-lens review file.pkb` → findings table/SARIF |
| F3 utPLSQL generation + execution | 16 | 15–19 ⚠ | Oracle container setup + compile/fix loop; **highest overrun risk** | `plsql-lens testgen … --run` → pass rate report |
| F4 Benchmark | 14 | 12–15 | corpus generation (delegated), scoring, before/after table | `make bench` regenerates `docs/benchmarks/` |
| Reserve | 12 | — | only with explicit approval | — |
| F5 Oracle→PostgreSQL | 13 cloud (F5a 7 + F5b 6) from the 24 USD left on 2026-10-30; F5c runs locally | — | F5b: proof on real PostgreSQL; meters under-reported up to 1.9× in F4 | `plsql-lens migrate corpus/` → findings; `rewrite_sql` validated on PostgreSQL |

**Stop rules:** at the end of each phase I report actual spend (`/cost`; `ccusage` is not installed) vs
budget and stop. If a phase is projected or measured at **> 125 % of its budget**, I stop and ask
before continuing. The reserve is never used without approval.

**Where the work runs:** the 69 USD credit applies only to **Claude Code cloud sessions**
(claude.ai/code / Claude Desktop → cloud). All phase work runs there, against the GitHub repo
`andresaragon/plsql-lens`. Consequences:
- The cloud session cannot reach the local Obsidian vault, `agy`, or the local `orquestador` plugin.
  Mechanical/parallel work uses Claude Code subagents (Sonnet/Haiku) instead of `/orquestador:*`;
  each phase report goes to `docs/reports/phase-N.md` and a short **local** session copies it into
  the Obsidian note.
- Docker availability in the cloud sandbox is **unverified**; first task of F3 checks it. Fallback:
  Oracle Free as a GitHub Actions service container (`workflow_dispatch`), results committed as artifacts.

**LLM backend (no API key):** the product talks to Claude through a `LLMProvider` interface with:
- `claude-cli` (default): runs `claude -p --output-format json` as a subprocess, so inside a cloud
  session it is billed to the same credit;
- `anthropic-api`: optional, only if `ANTHROPIC_API_KEY` is set;
- `fake`: recorded responses, used by every unit test.
Each run records the tokens and cost reported by the backend; the benchmark publishes them.

### F1 — Parser & inventory
- **Spike (measured, decision recorded in `docs/adr/0001-parser.md`):**

  | Option | License (to verify in spike) | Expected strength | Expected weakness |
  |--------|------------------------------|-------------------|-------------------|
  | A. ANTLR4 `grammars-v4/sql/plsql` + `antlr4-python3-runtime` | grammar Apache-2.0, runtime BSD-3 | most complete PL/SQL grammar | slow in Python, huge generated parser |
  | B. tree-sitter (any PL/SQL-capable grammar found) | per grammar | fast, error-tolerant | PL/SQL coverage likely poor |
  | C. `sqlglot` (Oracle dialect) | MIT | great for embedded SQL | does not parse PL/SQL blocks |
  | D. Hand-written tolerant lexer + structural recursive descent | ours (MIT) | fast, error-tolerant, only what rules need | we own the coverage |

  Likely outcome (hypothesis, not a decision): **D or A for PL/SQL structure + C for embedded SQL.**
  Metrics: parse success rate on the corpus, time per KLOC, inventory accuracy vs hand-labeled
  ground truth (units, params, call edges), install footprint.
- **Acceptance:** ≥ 95 % of corpus files parse without fatal error (partial IR allowed);
  inventory F1 ≥ 0.95 for units and ≥ 0.90 for call edges on the labeled set; Mermaid output renders.

### F2 — Review rules (deterministic first)

| Rule | Detects | Default severity |
|------|---------|------------------|
| PLL001 | `WHEN OTHERS THEN NULL` (and `WHEN OTHERS` without `RAISE`/logging) | high |
| PLL002 | Dynamic SQL built by string concatenation (`EXECUTE IMMEDIATE`/`OPEN FOR` without binds) | high |
| PLL003 | `COMMIT`/`ROLLBACK` inside a loop | medium |
| PLL004 | `SELECT … INTO` without `NO_DATA_FOUND`/`TOO_MANY_ROWS` handling in scope | medium |
| PLL005 | Row-by-row DML in cursor loops without `BULK COLLECT`/`FORALL` | medium |
| PLL006 | Implicit conversions (e.g. `VARCHAR2` vs `NUMBER`/`DATE` comparisons, `TO_DATE` without format) | low |
| PLL007 | Magic literals (repeated numeric/string literals outside constants) | info |

- Each finding: rule id, severity, file:line:col, message, rationale, optional fix hint.
- Output formats: table, JSON, **SARIF** (so it plugs into GitHub code scanning).
- Inline suppression: `-- plsql-lens: disable=PLL007`.
- LLM layer (`--explain`): explains a finding and proposes a patch; **never** creates or removes findings.
- **Acceptance:** every rule has ≥ 3 positive and ≥ 3 negative fixtures, all green; LLM layer tested with recorded responses.

### F3 — utPLSQL generation + real execution
- Oracle **Free** in Docker (candidate: `gvenzl/oracle-free:slim`) + utPLSQL installed by a script; `docker compose` file in repo.
- Flow: IR of a unit → prompt → utPLSQL test package → compile → run → on compile error, at most N (default 2) repair rounds → JUnit/JSON report.
- Reported metrics: compile rate, run rate, pass rate, repair rounds, tokens and USD per generated test.
- **Acceptance:** on the demo corpus, report produced end-to-end by one command; numbers published as measured (no target is promised before measuring).

### F4 — Benchmark (most important deliverable)
- Seeded-defect generator: takes clean packages, injects known defects per rule at known locations (ground-truth manifest), plus clean negatives.
- Scorer: precision, recall ("coverage") and F1 per rule; false-positive examples listed.
- `docs/benchmarks/`: methodology, corpus description, **before/after table** (before = first rule version, after = tuned rules), optional LLM-only baseline on a small sample for contrast, raw results JSON.
- **Acceptance:** `make bench` regenerates every table byte-for-byte from a fixed seed.

### F5 — Oracle→PostgreSQL migration hints (approved 2026-10-30)
M8 is a **new package** `src/plsql_lens/migrate/`. `parser/`, `rules/` and `docs/rules.md` stay frozen (the F4b seal), `review`
is unchanged and `RULES` keeps exactly PLL001–PLL007. Detection is deterministic: an LLM never decides whether a finding exists.
- **F5a — detection:** contract in `docs/migration-rules.md` (MIG001–MIG011: `NVL`, `DECODE`, `SYSDATE`/`SYSTIMESTAMP`,
  `seq.NEXTVAL`/`CURRVAL`, `ROWNUM`, `CONNECT BY`, `(+)`, `PRAGMA AUTONOMOUS_TRANSACTION`, `DBMS_OUTPUT`, `FROM DUAL`, the empty
  string literal `''`), library API `migrate_file`/`migrate_source`, command `plsql-lens migrate` (table, JSON, SARIF, `--fail-on`).
  The rules work on `parser.lexer.tokenize` of the whole file (the IR keeps only statement bodies, not declarations); the rules'
  `to_sarif` indexes `RULES`, so `migrate` writes its own SARIF.
- **F5b — safe rewrite + proof:** `rewrite_sql` applies the mechanical rewrites (`NVL`→`COALESCE`, `DECODE`→`CASE`, `seq.NEXTVAL`→
  `nextval('seq')`, `FROM DUAL` dropped) conservatively (never half-rewrites; idempotent; text outside the rewritten spans is
  untouched). Each case of `tests/fixtures/migrate/semantics.json` — expected results **observed on Oracle Free 23.26.3**, not
  written by an LLM — is run on PostgreSQL 16 (GitHub Actions service container; results published to branch `ci-results/f5`).
  Cases whose results differ for a reason outside the rewrite (e.g. Oracle's `''` = NULL) are labelled `known_divergence` and reported.
- **F5c — measurement (local):** per-rule counts on `corpus/` and an adjudicated sample, `docs/reports/phase-5.md`.
- **Out of scope (v1):** a full PL/SQL→PL/pgSQL transpiler, DDL, data types, `BULK COLLECT`/`FORALL`, `EXECUTE IMMEDIATE`,
  Oracle-supplied packages, package state, and any connection to a real database.
- **Acceptance:** a claim about a rewrite is made only if a command reproduces it; the evidence is correspondence on the
  reference cases, not a proof of general equivalence.

## 4. Commands

```bash
uv sync                                   # install
uv run pytest                             # unit tests (no network, no Docker)
uv run pytest -m integration              # needs Oracle container (docker compose up -d)
uv run ruff check . && uv run ruff format --check .
uv run mypy src
uv run plsql-lens inventory PATH [--format json|mermaid] [-o OUT]
uv run plsql-lens review PATH [--format table|json|sarif] [--explain]
uv run plsql-lens testgen PATH --unit PKG.PROC [--run]
uv run plsql-lens bench [--seed 42] [-o docs/benchmarks]
make demo-f1 | demo-f2 | demo-f3 | bench # one reproducible demo per phase
```

## 5. Project structure

```
plsql-lens/
├── src/plsql_lens/
│   ├── parser/      # lexer, IR dataclasses, structural parser, embedded-SQL bridge
│   ├── inventory/   # inventory builder, call graph, Mermaid renderer
│   ├── rules/       # one module per rule + registry + suppressions
│   ├── llm/         # Claude client wrapper, prompts, cost accounting
│   ├── testgen/     # utPLSQL generation + Oracle runner
│   ├── bench/       # defect seeding + scoring + report rendering
│   └── cli.py
├── tests/
│   ├── unit/        # no network, no Docker
│   ├── acceptance/  # written first, per phase
│   ├── integration/ # Oracle container (marked, separate CI job)
│   └── fixtures/    # small PL/SQL snippets written for this repo
├── corpus/          # third-party PL/SQL with provenance (see NOTICE)
├── docker/          # compose file + utPLSQL install script
├── docs/{adr,benchmarks,reports}/
├── README.md  README.es.md  LICENSE (MIT)  NOTICE  .env.example
└── .github/workflows/ci.yml
```

## 6. Code style

- Python ≥ 3.11 (CI matrix 3.11 / 3.13), `uv`, `ruff` (lint + format), `mypy --strict` on `src/`.
- Frozen `dataclasses` for the IR; no global state; pure functions from IR to findings.
- CLI with `typer`; library API usable without the CLI:

```python
from plsql_lens import parse_file, review

ir = parse_file("corpus/x/pkg.pkb")
for f in review(ir):
    print(f.rule_id, f.severity, f.location, f.message)
```

- Docs, code, commits and identifiers in English; `README.es.md` mirrors `README.md`.

## 7. Testing strategy

- **TDD:** acceptance tests for each phase are written first and committed **failing** (red) before the implementation that makes them pass.
- Unit tests: no network, no Docker, no API key. LLM calls go through an interface with a fake/recorded implementation.
- Integration tests (`-m integration`): Oracle container; CI job runs them only on `workflow_dispatch` / label, never blocking unit CI.
- Snapshot tests for IR, inventory and Mermaid; parametrized pos/neg fixtures per rule.
- Coverage gate: ≥ 85 % lines on `src/` excluding `testgen/runner` integration paths.

## 8. Boundaries

**Always**
- Work only inside `~/proyectos/plsql-lens`.
- Branches `feat/…`, `fix/…`, `docs/…`; PRs with `gh pr create --draft`.
- Every third-party file in `corpus/` listed in `NOTICE` with origin URL, commit, and license; only permissive licenses (MIT, Apache-2.0, BSD).
- Secrets only via environment (`.env.example` documents names, never values).
- Stop at the end of each phase with demo + measured report + spend; write `docs/reports/phase-N.md` (copied to the Obsidian note `03 - Proyectos/PL-SQL Lens.md` by a local session).
- Git identity `andresaragon <16310427+andresaragon@users.noreply.github.com>` (repo-local config).

**Ask first**
- Using the reserve, or continuing a phase projected > 125 % of budget.
- Adding a runtime dependency not named in this spec; changing the parser decision after the ADR.
- Any force-push or branch deletion.
- F5.

**Never**
- Code, schemas, names or data from the author's employer or any client.
- Push to `main`; force-push; committing secrets, IPs, or personal data (including personal email).
- Letting the LLM decide whether a finding exists.
- Background loops or polling.

## 9. Decisions (2026-10-22)

1. Git identity: `andresaragon <16310427+andresaragon@users.noreply.github.com>`, local to this repo.
2. The readings of the garbled brief lines below are confirmed.
3. No API key: LLM calls go through the `claude-cli` backend inside cloud sessions (see §3).
4. SPEC approved; phases run on Sonnet in Claude Code cloud sessions.

### Original questions (kept for the record)

1. **Git identity:** a personal address was offered, but rule 10 asks for a *noreply* address and forbids the personal email in commits. `gh` is logged in as `andresaragon` → `16310427+andresaragon@users.noreply.github.com`. Is that the GitHub account that will own the public repo?
2. **Garbled lines in the brief** — my reading, please confirm:
   - "Todo el PL/SQL de prueba es sin… repos abiertos" → *test PL/SQL is either written for this repo or taken from permissively-licensed open repos, cited in NOTICE*.
   - "TDD: los tests de aceptación se escriben…a pasar" → *written first, fail, then pass*.
   - "Tú ds el código de los issues" → *you (lead) review the workers' code*.
   - F3 "imagen Oracl… debe compilar" → *Oracle Free image; every generated test must compile and run*.
   - F4 "corpus sintético con defect… medición" → *synthetic corpus with seeded known defects and measurement*.
   - F5 "…acle→PostgreSQL" → *Oracle→PostgreSQL migration assistant*.
   - "al cierre de cada fase … lo presupuestado" → *compare spent vs budgeted*.
3. **API key for the product's own LLM calls** (F2/F3/F4): will you provide an `ANTHROPIC_API_KEY` with its own budget? Default models proposed: `claude-haiku-5-5` for explanations, `claude-sonnet-5-5` for test generation (to be confirmed against current pricing in F2).
4. **Model switching:** I can't change models myself — please run `/model` to Sonnet once this spec is approved.
