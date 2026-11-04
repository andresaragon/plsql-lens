# Sample migration audits

Reports produced with `plsql-lens migrate` on public PL/SQL code that the tool was **not** developed against (it is not in
`corpus/`). They are samples: what the tool sees, what it does not, and a small manual review marked as provisional.

| Project | Commit | License | Report |
|---|---|---|---|
| [oos-utils](https://github.com/OraOpenSource/oos-utils) | `b6217292bc744211eaee9e1d11ca7a0b495bc44d` | MIT | [English](oos-utils/migration-audit.md) · [Español](oos-utils/migration-audit.es.md) |

Uses the migration rules MIG001–MIG017 of `main` (revision 2, 2026-11-04); the report must be regenerated when newer rules are merged.

## Contents of `oos-utils/`

* `raw/` — raw output of the tool: `migrate.json`, `migrate.txt`, `inventory.json`, `callgraph.mmd`, `scope.json` (files and
  lines analyzed) and `meta.txt` (URL, commit, license file hash, tool version).
* `review.json` — the manual review of the sample (verdict and reason per finding).
* `tables.py` — generates the numeric blocks of both reports from `raw/` and `review.json`, and checks that they match.
* `migration-audit.md`, `migration-audit.es.md` — the reports.

The third-party code is **not** stored here: only its URL, the pinned commit and the tool's output.

## Reproduce

```bash
bash scripts/demo_migration_audit.sh                 # needs git, uv and access to github.com
uv run python docs/demo/oos-utils/tables.py          # fails if a report no longer matches raw/ and review.json
```

The script clones the project into a temporary directory at the pinned commit, checks that it got that commit, runs the tool
with a relative path (so the output does not depend on the temporary directory) and rewrites `raw/`. Running it twice gives
identical files while `src/` does not change (`meta.txt` records the last commit that changed `src/`).
