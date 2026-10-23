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

Third-party PL/SQL used as test input lives in `corpus/` and is listed in [NOTICE](NOTICE).
License: MIT.
