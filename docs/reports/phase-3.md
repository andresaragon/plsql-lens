# Phase F3 report — utPLSQL test generation and real execution

Date: 2026-10-23. Branch `feat/f3-testgen` (single draft PR; nothing merged).

## What was built
* `plsql-lens testgen PATH --unit PKG.PROC [--run]`: prompt (unit source + package spec + only the DDL the unit
  touches, including constraints and one level of foreign-key parents) → utPLSQL package from the LLM →
  compile on Oracle → on a compile error send the Oracle message back, at most `--max-repairs` (default 2) →
  run with utPLSQL → JUnit XML + JSON metrics.
* `plsql-lens testgen-setup` / `testgen-suite`: install the targets; run the committed tests (no LLM);
  `--generate` (costs money) and `--repair-from report.json` (repairs only what failed to compile).
* Oracle access has no Python driver: a shell command (`PLSQL_LENS_SQLPLUS`) pipes scripts into `sqlplus`;
  credentials only through environment variables.
* 30 target units (7 easy / 10 medium / 13 hard) in `tests/fixtures/testgen/manifest.json`, each with the
  reason it was chosen: 19 in four packages written for this repo (pure functions, string helpers, an order
  workflow over two tables, HR-sample reporting), 9 from OraOpenSource Logger, 2 from the Oracle HR sample.
* Carry-over from F2: SARIF output validated against the official 2.1.0 JSON Schema (vendored from
  microsoft/sarif-sdk, MIT, recorded in NOTICE; `jsonschema` is a dev dependency only). The existing output
  already conformed, so this test was green from its first run.

## Environment decision (evidence)
`docker info` in the cloud session: the Docker client is installed but **no daemon runs** (`failed to connect
to the docker API at unix:///var/run/docker.sock`); `dockerd` exists but starting it would be a background
process (forbidden by the session rules) and was not attempted. Decision: **GitHub Actions**.
`.github/workflows/oracle.yml` starts `gvenzl/oracle-free:23.26.3-slim` through `docker/compose.yml`
(healthy in ~20 s), installs utPLSQL v3.1.14 with `docker/setup.sh` (SHA-256 pinned), runs setup and the
suite, and publishes `report.json`/`junit.xml`/logs to the branch `ci-results/f3`. Two practical findings:
* Artifact and log-archive downloads are blocked from the cloud session's network policy, so results are
  published to a git branch and fetched with `git fetch`.
* A `workflow_dispatch` workflow must exist on the default branch to be dispatchable; until this PR is
  merged the job also triggers on pushes to `feat/f3-**` that touch the test bed. After merging it can be
  restricted to `workflow_dispatch` only.
The Oracle image is pulled from Docker Hub under Oracle's own license and is not redistributed (README, `docker/`).
The slim image supports utPLSQL fully (install log: `docs/reports/phase-3/setup-utplsql.log`).

## `claude -p` overhead and the decision
Same generation prompt, Sonnet (`scripts/measure_cli_overhead.py`, raw numbers in
`docs/reports/phase-3-cli-overhead.json`):

| Unit | Mode | Input tokens | Output tokens | USD |
|---|---|---|---|---|
| pkg_calc.clamp | default | 40 836 | 2 850 | 0.0905 |
| pkg_calc.clamp | lean flags | 2 811 | 2 258 | 0.0338 |
| pkg_orders.add_item | default | 41 965 | 4 563 | 0.1081 |
| pkg_orders.add_item | lean flags | 3 940 | 4 408 | 0.0598 |

Lean flags (`--system-prompt … --tools "" --disable-slash-commands --strict-mcp-config --setting-sources ""
--no-session-persistence`, all from `claude --help`) cut input from ~41 k to ~1.3 k tokens beyond the prompt
(−93 %) and cost by 45–63 %. `--bare` was tried and returns nothing in this environment. **Decision:** lean flags
are the default of `ClaudeCliProvider`; **no batching**, because output tokens (2–4 k per unit) now dominate and
one unit per call keeps parsing and repair simple. Cost projection before the full run: 30 units × ~0.05 USD ≈
1.5 USD generation plus repairs; actual 1.37 USD, far below the 20 USD stop line.

## Metrics (final committed tests, run on Oracle; `docs/reports/phase-3/report.json`, `summary.md`)
| Slice | Units | Compiled | Ran | Tests | Passed | Failed | Errored | Repair rounds | Assertions/test | Tokens in/out | USD | USD/test |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Total** | 30 | 30 (100.0 %) | 30 | 405 | 390 | 8 | 7 (96.3 % pass) | 1 | 1.27 | 144547/83998 | 1.418 | 0.0035 |
| easy | 7 | 7 (100.0 %) | 7 | 96 | 96 | 0 | 0 (100.0 % pass) | 0 | 1.44 | 33057/12787 | 0.260 | 0.0027 |
| medium | 10 | 10 (100.0 %) | 10 | 138 | 135 | 3 | 0 (97.8 % pass) | 0 | 1.39 | 45047/24325 | 0.423 | 0.0031 |

| hard | 13 | 13 (100.0 %) | 13 | 171 | 159 | 5 | 7 (93.0 % pass) | 1 | 1.09 | 66443/46886 | 0.735 | 0.0043 |

Per-unit table: `docs/reports/phase-3/summary.md`. There is no target for these numbers; they are published as
measured. Compile rate counts the committed tests after repair; the **first-shot** rates are in the history:

| Generation | Prompt | Repairs | Compiled | Tests | Passed | Failed | Errored | LLM USD |
|---|---|---|---|---|---|---|---|---|
| round 0 (`history/v1-round0-report.json`) | v1 (no FK parents) | 0 | 28/30 | 387 | 326 | 4 | 57 | 1.335 |
| round 1 (`history/v2-round1-report.json`) | v2 | 0 | 29/30 | 395 | 380 | 8 | 7 | 1.371 |
| **final** (`report.json`) | v2 | 1 (`top_earner`) | **30/30** | 405 | 390 | 8 | 7 | 1.418 |

What moved the numbers: v1 → v2 added foreign-key parent tables and constraint DDL to the prompt and an
instruction to reuse existing parent rows (HR tests had invented job/department ids: 7+6+4+7 constraint
violations in v1). The round-0 `pkg_text` errors were a defect in this repo's own fixture (see failures).
Only compile errors trigger repairs (as specified); runtime failures are reported, not repaired.

## Failure classification (details and evidence: `docs/reports/phase-3/failures.md`)
15 tests did not pass: **12 bad tests** (11 in `logger.log_error` from one upper-case scope mistake, 1 in
`logger.get_pref`) and **3 real defects**, all in this repo's own `pkg_text` fixture: NULL input to
`mask_email` (2) and `truncate_text` (1) violates the function's own header comment because NULL vanishes in
`||`. These defects were not planted; they surfaced from the generated tests. A fourth, `is_palindrome` using
the SQL-only `REVERSE`, was found by the first Oracle run before any generated test executed.

## Known gaps
* Pass rate is not test quality: only 1.27 assertions per test on average (hard units 1.09), and tests that
  assert "no row" pass vacuously when the setup is wrong (documented in `failures.md`).
* Targets are small; 19 of 30 are written for this repo and the generator saw their header comments, which
  makes the contract explicit. Third-party Logger units had no such comments beyond the spec.
* One repair happened (1 of 30), so the repair loop is exercised by fakes and by that single real round, not
  by a large sample.
* Runtime-failure repair, mutation testing and coverage measurement are not implemented.
* No Docker in the cloud session: the local-Docker path (`docker/up.sh`, `make demo-f3`) is written but was
  run only inside Actions. The results branch `ci-results/f3` is a CI convenience, not product code.
* Prompt v2 was regenerated for all 30 units after the v1 run; v1 numbers are kept as history, not hidden.

## Demo
```bash
make demo-f3     # runs the COMMITTED tests on Oracle (Docker if available, else the Actions job); no LLM
make testgen-f3  # regenerates all tests with the LLM; costs money (~1.4 USD measured)
make help
```

## Spend (estimate — `/cost` is not readable from inside the session)
Measured LLM spend through the product (reported by `claude -p`): round 0 1.335 + final 1.371 + repair 0.047
+ overhead measurement 0.292 + F2 smoke call = **≈ 3.05 USD**. Lead (session) usage is not measurable here; from
token volume I estimate **6–9 USD**, so **F3 ≈ 9–12 USD against 16 USD**, no subagents used, reserve untouched.
**Measured (2026-10-22):** the cloud credit balance went from 59 to 50 USD during F3, so F3 cost **9 USD**
against its 16 USD budget. That figure includes the ≈ 3.05 USD of product LLM calls, which run inside the session.

## Left for F4
Seeded-defect benchmark corpus and scorer (the real precision/recall for the F2 rules); the test-generation
metrics here are not that benchmark.
