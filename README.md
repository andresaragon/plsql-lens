# PL/SQL Lens

Python library + CLI that analyzes Oracle PL/SQL packages. Status: **Phase F1 (parser & inventory)**
is implemented; review rules, utPLSQL generation and the benchmark are planned (see [SPEC.md](SPEC.md)).

## Quick start

```bash
uv sync
uv run plsql-lens inventory corpus/ --format json -o inventory.json
uv run plsql-lens inventory corpus/ --format mermaid -o callgraph.mmd   # --level unit for subprograms
uv run pytest            # unit + acceptance tests, no network, no Docker
make demo-f1             # regenerates docs/reports/phase-1/
```

```python
from plsql_lens import parse_file, build_inventory

ir = parse_file("corpus/logger/logger.pkb")  # IR: units, subprograms, params, call sites
inv = build_inventory(["corpus/logger"])  # units + resolved call edges
```

## What F1 does

* Tolerant lexer + structural recursive-descent parser (no external parser dependency); it never raises
  on unknown syntax and reports structural problems in `FileIR.issues`.
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


Third-party PL/SQL used as test input lives in `corpus/` and is listed in [NOTICE](NOTICE).
License: MIT.
