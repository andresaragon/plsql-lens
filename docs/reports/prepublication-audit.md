# Pre-publication audit of `plsql-lens`

Audited commit: `main` @ `a1e4ea0` (24 commits on `main`; 125 commits reachable from all refs, see H1). Date: 2026-10-30.
This is a read-only audit: nothing was changed, rotated, deleted or fixed. The report is written to be published with the
repository, so it contains no secret and no personal value: e-mail addresses appear only by type and location.

## Verdict: ready with actions

**No real secret was found** in the working tree, in any of the 125 commits reachable from any ref (branches, the 24 pull-request
heads, the three `ci-results/*` branches; there are no tags), or in the CI result files. The tree and the history contain no
personal e-mail address in any file or commit message, no local path, no IP address and no employer or client material.

Nothing blocks publishing, but these should be done or decided first (details in the table and in *Actions for the owner*):

1. Settings that have to be changed when the repository is made public, one of which `SECURITY.md` already promises (O1, O6).
2. Workflow permissions: three workflows rely on the repository default token permissions and two have `contents: write` (O2).
3. The README states two things that a command contradicts or does not support: the parser "never raises" (R2) and the phase-2
   sample outputs (R1).
4. The history that would become public is 125 commits, not 24, because of the pull-request refs, and it includes the one commit
   whose author is an institutional e-mail (H1, P1; already decided "leave as is", reflected here, not reopened).

## How the audit was done

| Item | Value |
|---|---|
| Tools | `git` 2.43.0, `uv` 0.11.32, `uvx detect-secrets` **1.5.0** (27 plugins, default configuration), Python 3.13 |
| Scope of history | `git log --all` after also fetching the pull-request heads (`refs/pull/*/head`): 125 commits, 24 of them on `main` |
| Scanner control | A file with one documented fake AWS example key and one fake `sk_live_`-shaped string, scanned the same way, gives 2 findings (so a silent scanner would have been noticed; an earlier run without `--all-files` was vacuous and was discarded) |
| Network | none beyond fetching this repository; no LLM, no Oracle, no PostgreSQL |

The commands are in *Commands* at the end; findings cite them as `C1`…`C14`.

## Findings

Severity: **high** = fix before publishing; **medium** = decide or fix before publishing; **low** = fix soon; **info** = no action
needed, recorded for completeness. *Who*: owner = repository owner; repo = a change in the repository.

| ID | Sev. | Category | Where | Evidence (redacted) | Recommendation | Who |
|---|---|---|---|---|---|---|
| S1 | info | secrets | whole tree, 125 commits, `ci-results/f3`, `ci-results/f5`, `ci-results/f5-differential` | No match for `sk-ant-`, `ghp_`/`github_pat_`/`gh[ousr]_`, `AKIA…`, `xox…`, `AIza…`, `-----BEGIN … PRIVATE KEY-----` (C2). No literal value after `PASSWORD`/`PGPASSWORD`/`ORACLE_PASSWORD`/`API_KEY`/`TOKEN` assignments: only placeholders such as `<pw>` and `${ORACLE_PASSWORD:?…}` (C3). `detect-secrets` flags 14 files in the tree and 428 findings in the history, all `Hex High Entropy String`, and every one is a 32-, 40- or 64-hex digest (checksums in `docs/benchmarks/**`, `docker/setup.sh`, test baselines, Git SHAs), not a secret (C4, C5). The only secret-looking file name ever committed is `.env.example`, which holds variable names with values commented out (C6). | None. Optionally add a `detect-secrets` baseline or enable GitHub secret scanning (O6). | – |
| S2 | info | secrets | `ci-results/f3`, `ci-results/f5`, `ci-results/f5-differential` | The three branches hold CI logs, `junit.xml` and JSON: no e-mail, no credential, no host. The words "token/password" there are LLM `input_tokens`/`output_tokens` counters (C7). The only path is the generic runner path `/home/runner/work/…` in `ci-results/f5:pytest.log`. `ci-results/f3:report.json` also records LLM token counts and `cost_usd` per unit. | None required. Decide whether publishing the LLM spend figures is fine; the branches can be deleted without affecting `main`. | owner |
| P1 | medium (decided) | personal data | commit `3afe6ea` ("F1: parser & inventory (#1)"), author field | 1 of 125 commits has an **institutional e-mail** as author (and the committer is GitHub's own merge identity). The other 124 authors are the `…@users.noreply.github.com` address; committers are the same noreply address (102) or GitHub's `web-flow` identity (23). The address appears in commit metadata only: it is not in any file or commit message (C8, C9). The commit is the 2nd on `main`; 22 commits on `main` and 23 pull-request heads descend from it (C13). | Owner decision recorded: "leave as is". Options if reopened are in *History privacy*. | owner |
| P2 | low | personal data | `docs/benchmarks/external/README.es.md:6` | The owner's first name appears once, in a sentence about who did not write the split. The GitHub handle appears in `LICENSE`, `pyproject.toml`, docs and workflows (public identity, expected). | Check that the sentence is meant to be public; otherwise reword. | owner |
| P3 | info | personal data | commit messages (all refs) | 146 trailers `Claude-Session: https://claude.ai/code/session_…` (4 distinct sessions) and 201 `Co-Authored-By: … <noreply@anthropic.com>` lines. The session links point to private conversations (whether a stranger can open them was not verified). They cannot be removed without rewriting history. | Decide whether to keep the session trailer in future commits. | owner |
| P4 | info | personal data | whole tree and history | No local path (`/home/<user>`, `/mnt/…`, `C:\…`), no IP address, no non-public host: hosts in URLs are `www.apache.org`, `github.com`, `www.w3.org`, `utplsql.github.io`, `stackoverflow.com`, `json.schemastore.org`, `api.anthropic.com`, `semver.org`, `pypi.org`, `keepachangelog.com`, `docs.astral.sh`, `blogs.oracle.com` (C10). E-mail-shaped strings in files are the GitHub noreply address (workflows, `SPEC.md`) and synthetic addresses in test fixtures (`example.com` and similar). No reference to an employer or a client: the only matches are the policy statements in `NOTICE` and `SPEC.md` ("nothing from any employer or client") and a Spanish rule against using them (`docs/benchmarks/human/README.es.md:10`). | None. | – |
| L1 | info | licenses | `NOTICE`, `corpus/`, `tests/vendor/`, `tests/fixtures/testgen/**`, `docs/benchmarks/data/` | Every third-party tree has a licence copy next to the files, and the copies match `NOTICE`: utPLSQL Apache-2.0 (`corpus/utplsql/LICENSE`, also `docs/benchmarks/data/LICENSE.utplsql`, byte-identical), Logger MIT (`corpus/logger/LICENSE`, `tests/fixtures/testgen/logger/LICENSE`, identical), Oracle sample schemas MIT text (`corpus/oracle-db-sample-schemas/LICENSE`, `tests/fixtures/testgen/hr/LICENSE`, identical), SARIF SDK MIT (`tests/vendor/LICENSE.sarif-sdk`). The files listed in `NOTICE` exist: 3 Logger files and 4 Oracle sample files in `corpus/`, 257 utPLSQL sources (27 `.pkb`, 27 `.pks`, 85 `.tpb`, 117 `.tps`, 1 `.trg`), and the `tests/fixtures/testgen` copies (2 Oracle sample files, 9 Logger files) (C11). 256 of the 257 copied utPLSQL source files keep an upstream header in their first lines; the one without is `corpus/utplsql/core/annotations/ut_trigger_annotation_parsing.trg`. MIT (this repo) with Apache-2.0 and MIT material is compatible; the Apache files stay under Apache-2.0, as `NOTICE` says. | None. | – |
| L2 | low | licenses / provenance | `docs/benchmarks/external/data/**` (41 files), `tests/generated/**` (60), `docs/benchmarks/llm_baseline/` (1), `tests/fixtures/**`, benchmark templates | These contain text written by LLMs (an external split authored by a Gemini model, per `docs/benchmarks/external/README.md:1-6`; generated utPLSQL tests; recorded LLM responses; templates by Claude subagents). `NOTICE` lists only human third-party sources. Whether the providers' terms allow relicensing the output under MIT was not checked. | Add a short "AI-generated content" entry to `NOTICE` (what, which model, where) and confirm the provider terms. | owner / repo |
| L3 | low | licenses | `NOTICE` item 1 | Apache-2.0 §4 asks that an upstream `NOTICE` file, if one exists, travels with the copies. Whether the pinned utPLSQL commit has one, and whether the three commits and licences in `NOTICE` are the ones upstream has, was **not verified** (no access to the upstream repositories from here). | Confirm against upstream once; add the upstream `NOTICE` text if there is one. | owner |
| L4 | info | licenses | `docker/compose.yml:6`, `.github/workflows/postgres.yml:35`, `docker/setup.sh:17-19` | Images and downloads, none redistributed: `gvenzl/oracle-free:23.26.3-slim` (Oracle Database Free, under Oracle's own terms; the README says so), `postgres:16`, utPLSQL `v3.1.14` downloaded from the project's release and pinned by SHA-256. The terms of each image were not read here. | Keep the README sentence; re-read the Oracle Free terms before advertising the Docker flow. | owner |
| L5 | info | licenses | `pyproject.toml:8` and the lock | Runtime dependency `typer` (MIT) and its permissive dependencies (`rich` MIT, `pygments` BSD-2-Clause, `shellingham` ISC, `typing-extensions` PSF-2.0). Development-only: `hypothesis` is **MPL-2.0** (weak copyleft; not bundled in the wheel or sdist), `pytest`, `jsonschema`, `pyyaml`, `mypy`, `ruff` MIT (C12). | None. | – |
| R1 | low | claims | `README.md:70`, `docs/reports/phase-2/*` | The README points to `docs/reports/phase-2/` as sample output and `make demo-f2` as the way to regenerate it. Regenerating gives files that differ from the committed ones (`review.txt`, `review.json`, `review.sarif`, `counts.md`): the committed samples predate the rule tuning (PLL004 12→9, PLL006 19→13, PLL007 420→413 findings over the corpus) (C12). | Regenerate and commit the samples, or say in the README that they are the F2 snapshot. | repo |
| R2 | medium | claims | `README.md:133` ("it never raises on unknown syntax") | `docs/reports/robustness.md` already records four inputs that make the parser raise or take seconds (a `RecursionError` at 495 nested subprograms, three quadratic cases). In addition, the manual robustness sweep (`tests/robustness`, not part of the default run) **fails on `main` today**: the new migrate fixtures enlarged the seed pool, so the fixed seed now draws a mutation of `tests/fixtures/migrate/rules/MIG006/neg_2.pkb` (about 130 KB of repeated `LOOP;`) on which `parse` takes about 10 s in `statements.py` (limit 2 s), a fifth case not in the report (C14). | Qualify the sentence (for example "does not raise on ordinary syntax errors; pathological inputs are listed in `docs/reports/robustness.md`"), and record the fifth case. | repo |
| R3 | low | claims | `README.md:29` ("no network, no Docker") | `uv run pytest` does not need them, but `tests/unit/test_packaging.py` builds the package and installs it when the package index is reachable (it skips offline). | Say "no network required". | repo |
| R4 | low | claims | `README.md:86` | "checks the action on every push with `action-selftest.yml`": the workflow runs on pull requests, on pushes to `main` and on manual dispatch, not on every push. | Reword. | repo |
| R5 | info | claims | `docs/github-action.md:50-53`, `README.md:85` | Text about using the action from another *private* repository (including the sentence that the access setting is `none`) becomes obsolete when the repository is public. | Update the text when publishing. | repo |
| O1 | medium | operations | `SECURITY.md:7-12` | The policy has two flows: issues "while the repository is private" and, once public, GitHub's private vulnerability reporting, which "has to be enabled in its settings". Until it is enabled the Security-tab link does not work for outsiders. | When publishing, enable private vulnerability reporting and shorten `SECURITY.md` to the public flow. | owner, repo |
| O2 | medium | operations | `.github/workflows/ci.yml`, `action-selftest.yml`, `robustness.yml` (no `permissions:`); `oracle.yml:19-20`, `postgres.yml:18-19` (`contents: write`) | The first three inherit the repository's default token permissions (not verified: it may be read/write). `oracle.yml` and `postgres.yml` need `contents: write` to push `ci-results/*` and do so with the token embedded in a `https://x-access-token:…@github.com/…` URL (`oracle.yml:55`, `postgres.yml:53`, masked in logs). They run only on `workflow_dispatch` (write access needed) and on pushes to `feat/f3-**` / `feat/f5-**` (only collaborators can push to this repository; a fork cannot trigger them). No workflow uses `secrets.*` or `pull_request_target`. | Set the default workflow permissions to read-only; add `permissions: contents: read` at the top of the three workflows; keep `write` only for the publishing step or a separate job. | owner, repo |
| O3 | low | operations | all workflows, `action.yml:27,44` | Actions are pinned by tag (`actions/checkout@v4`, `astral-sh/setup-uv@v5`, `actions/upload-artifact@v4`, `github/codeql-action/upload-sarif@v3`), not by commit SHA. | Pin by SHA and enable Dependabot for `github-actions`. | repo |
| O4 | info | operations | `ci.yml` (`push: **`, `pull_request`), `action-selftest.yml` | A pull request from a fork runs `ci.yml` and the self-test with a read-only token and no secrets (`pull_request`, not `pull_request_target`); it executes the fork's code on a GitHub runner, so the exposure is cost, not credentials. | Require approval to run workflows for first-time contributors (O6). | owner |
| H1 | medium | history | all refs | The history that becomes public is **125 commits, not 24**: `main` has 24 (squash merges), and the 24 pull-request heads (`refs/pull/*/head`) keep the 101 pre-squash commits, work-in-progress commits and the same author metadata (C13). Rewriting `main` alone would not remove commits that the pull-request refs still hold. | See *History privacy*. | owner |

### O6. Checklist to apply when the repository is made public

* Description, topics and homepage (the owner reports none is set; not verifiable from here).
* Private vulnerability reporting (O1), secret scanning and push protection, Dependabot alerts and updates (including GitHub Actions).
* A branch ruleset for `main`: pull request required, status checks `checks (3.11)`, `checks (3.13)` and `build`, no force-push.
* Actions: read-only default token, approval required for first-time contributors (or all outside collaborators), and the allowed-actions policy.
* Decide whether the `ci-results/*` branches stay (they contain only CI output) and whether Issues, Discussions and Wiki are on.
* Check the text of issues and pull-request descriptions: they become public and were **not scanned** here (see *Not verified*).

## 1. Secrets

Working tree, history of all refs and the three `ci-results/*` branches were scanned for provider token prefixes, private-key
blocks, `PASSWORD`/`PGPASSWORD`/`ORACLE_PASSWORD` assignments with a value, `.env`-style file names and high-entropy strings
(S1, S2). Result: no secret. The credential handling the README describes is what the code does: `ANTHROPIC_API_KEY` is read from
the environment (`src/plsql_lens/llm/providers.py`), the Oracle command comes from `PLSQL_LENS_SQLPLUS`, and the workflows
generate throw-away passwords with `openssl rand` and mask them with `::add-mask::`.

## 2. Personal and third-party data

Identity metadata is summarized in P1; content, paths and hosts in P4; the CI branches in S2. The first-name mention (P2) and the
session links (P3) are the only identity-related items beyond P1.

## 3. Licenses and provenance

See L1–L5. The licence copies are present and identical to the ones listed in `NOTICE`; what could not be checked is the upstream
side (commits, `NOTICE` files, current licence text) and the terms of the Docker images and of the providers of AI-generated
content.

## 4. Do the README claims reproduce?

Commands were run from this checkout (outputs to a scratch directory) or, for the targets that write into `docs/`, from a throw-away
export of `origin/main`, and compared with the committed files. "Not reproducible here" means it needs Oracle, PostgreSQL, an LLM
or GitHub itself.

| Claim (README) | Command | Result | Status |
|---|---|---|---|
| Install from the lock | `uv sync` | installs the locked environment | reproduced |
| `inventory … --format json` produces the inventory (the F1 demo file) | `uv run plsql-lens inventory corpus/ --format json -o inventory.json` | exit 0; byte-identical to `docs/reports/phase-1/inventory.json` | reproduced |
| `inventory … --format mermaid` (and `--level unit`) | `… --format mermaid -o callgraph.mmd`, and with `--level unit` | exit 0; identical to `phase-1/callgraph.mmd`; unit level 1232 lines | reproduced |
| `review` prints a table of findings | `uv run plsql-lens review corpus/logger/logger.pkb` | exit 0, 97 lines | reproduced |
| "unit + acceptance tests, no network, no Docker" | `uv run pytest` | 977 passed, 64 deselected, 16 s; `test_packaging.py` uses the network when reachable | reproduced, with R3 |
| `make demo-f1` regenerates `docs/reports/phase-1/` | `make demo-f1` | identical to the committed files | reproduced |
| Python snippet (`parse_file`, `build_inventory`) | the snippet | runs; `FileIR`, 1 unit; `Inventory` | reproduced |
| `review … --format json -o review.json` | the command | exit 0; differs from the committed `phase-2/review.json` | command reproduced; sample **different** (R1) |
| `review … --format sarif` is SARIF 2.1.0 | the command | `version` 2.1.0, 95 results; schema validation is in `tests/unit/test_sarif_schema.py` (passes) | reproduced |
| `review corpus/ --rules PLL001,PLL002` limits the rules | the command | only `PLL001`, `PLL002` | reproduced |
| "an unknown id is an error" | `review … --rules NOPE` | exit 2 | reproduced |
| `--fail-on` exits 1 at the threshold, `never` always 0 | `review … --fail-on high`, `--fail-on never` | exit 1, exit 0 | reproduced |
| `make demo-f2`: "the three formats + per-rule counts in `docs/reports/phase-2/`" | `make demo-f2` | exit 0; `review.txt`, `.json`, `.sarif` and `counts.md` differ from the committed ones | **different** (R1) |
| `review … --explain` | the command with `--explain` | needs an LLM | not reproducible here (LLM) |
| "seven deterministic rules" | `python -c "from plsql_lens.rules import RULES; print(len(RULES))"` | 7 (PLL001–PLL007) | reproduced |
| `migrate` prints a table | `uv run plsql-lens migrate corpus/logger/logger.pkb` | exit 0, 61 lines | reproduced |
| `migrate … --format sarif` | `migrate corpus/ --format sarif -o migrate.sarif` | exit 0 (schema validation in the unit tests) | reproduced |
| `migrate corpus/ --rules MIG008,MIG011 --fail-on high` exits 1 | the command | exit 1 | reproduced |
| "eleven rules", "234 findings in 42 of 264 files" | `migrate corpus/ --format json` | 11 rules; 234 findings in 42 files; 264 PL/SQL files | reproduced |
| "140 of 234 adjudicated"; "2 of the 8 `''` are benign, 6 traps" | `docs/reports/phase-5/adjudication.json` | 140 items; `MIG011`: 2 benign, 6 semantic-trap | reproduced |
| "42 cases on PostgreSQL 16: 37 give the same result, 5 differ" | `PLSQL_LENS_PSQL=… pytest tests/integration/test_migrate_postgres.py -m integration` | needs PostgreSQL. CI evidence: workflow `postgres`, branch `ci-results/f5`, PostgreSQL 16.15, 42 cases, 37 match, 5 divergent as documented, 0 mismatch (run on a feature-branch commit with the same rewrite code) | not reproducible here (PostgreSQL); CI evidence consistent |
| `make bench` regenerates everything without an LLM | `plsql-lens bench -o <copy of docs/benchmarks>` | exit 0, 3 s, byte-identical to `docs/benchmarks` | reproduced |
| 350 defects, 350 hard negatives, 7 rules, 105 files; precision 1.000, recall 0.998, 464 TP / 0 FP / 1 FN; "before" scores the same | `docs/benchmarks/results.md` (regenerated above) | 105 files, 350 regions, 350 hard negatives, test: 464/0/1 before and after | reproduced |
| "LLM-only baseline costs 1.13 USD" | sum of `cost_usd` in `docs/benchmarks/llm_baseline/` | 40 entries, 1.13 USD (recorded; re-running needs an LLM) | recorded value reproduced; run not reproducible here (LLM) |
| External split: 64 TP / 2 FP / 0 FN strict, 65 / 1 / 0 adjudicated, 0 of 9 `beyond` | `plsql-lens bench-external report` | `docs/benchmarks/external/` byte-identical | reproduced |
| `bench-external convert\|run\|run-before` | not run | the engine runs once on the sealed cases and refuses a second run (`phase-4b.md`) | not run |
| `bench-llm`, `bench-external llm`, `testgen`, `testgen-setup`, `testgen-suite --generate` | not run | need an LLM and/or Oracle | not reproducible here (LLM, Oracle) |
| `make help` | `make help` | lists `demo-f3`, `testgen-f3`, `help`, `bench`, `bench-llm` | reproduced |
| `make demo-f3`, `make testgen-f3`, `testgen corpus/logger/logger.pkb --unit logger.sprintf …` | not run | need Oracle (and an LLM for the last two) | not reproducible here (Oracle, LLM) |
| "the parser never raises on unknown syntax" | `uv run pytest tests/robustness -m robustness` | 14 passed, 4 xfailed (known), **1 failed** | **different** (R2) |
| The action runs `review`, writes SARIF and gates on `fail-on` | `uv run pytest tests/unit/test_action.py` (in `pytest`) | passes; the real run needs GitHub | reproduced locally; GitHub run not reproducible here |
| The repository checks the action "on every push" | `.github/workflows/action-selftest.yml` | triggers: pull requests, push to `main`, manual dispatch | **different** (R4) |
| Passwords "come from the environment only" | section 1 | no literal credential anywhere | reproduced |

The README's `bash` blocks are all covered: Quick start (6 lines), Review (5 lines and the `--explain` line), Migration (3 lines)
and F3 (4 lines).

## 5. Operational risks of a public repository

See O1–O6. In short: pull requests from forks run the CI with a read-only token and no secrets, which limits the risk to compute
cost; manual dispatch and the `feat/f3-**` / `feat/f5-**` push triggers need write access to the repository; the two workflows
that publish results need `contents: write` and put the token in a clone URL; `action.yml` takes its inputs through `env`, not by
interpolation into the script, installs from its own checkout and uploads SARIF only when asked; actions are pinned by tag only.

## 6. History privacy

Counts (C8, C13): 125 commits reachable from all refs; 124 have the GitHub noreply address as author; 1 (`3afe6ea`) has an
institutional e-mail as author; 23 have GitHub's `web-flow` identity as committer (it is GitHub's merge identity, not a person);
none has a personal e-mail. `3afe6ea` is the second commit on `main` and is an ancestor of 22 commits on `main`, of 23 pull-request
heads and of the 6 other remote branches (excluding `ci-results/*`). Current decision: **leave as is**. Options if that changes (none was executed):

| Option | Effect | Cost |
|---|---|---|
| Keep | Nothing changes; the address stays in the metadata of 1 commit and is public once the repository is | none |
| `.mailmap` file | Hides the address in `git log`/`shortlog` output | cosmetic: the raw commit object and the web UI still show it |
| Rewrite with `git filter-repo --mailmap` on `main` | New SHAs for that commit and its 22 descendants | the 24 pull-request heads and the 6 other branches keep the old commits unless the repository is recreated (pull-request refs cannot be deleted by the owner; whether GitHub Support removes them was not verified); links and the `ci-results/*` result commits refer to old SHAs |
| Publish a fresh repository from the current tree | One initial commit (or a rewritten history): no old author, no pull-request refs, no session trailers | loses the commit history and the pull-request trail; stars/links start over |

## Actions for the owner

1. Decide P1 again only if you change your mind; if you do, choose the last option (a fresh repository) because of the pull-request
   refs (H1).
2. Enable private vulnerability reporting, secret scanning with push protection, Dependabot, a `main` ruleset and read-only default
   workflow permissions; set description, topics and homepage (O1, O2, O6).
3. Confirm L2 (AI-generated content terms) and L3 (upstream `NOTICE` for utPLSQL) and add the AI-content entry to `NOTICE`.
4. Review the text of issues and pull requests (they become public) and P2/P3.
5. Ask for the repository changes you want: add `permissions:` to three workflows (O2), qualify the README sentences (R2–R4),
   regenerate the phase-2 samples (R1), update the private-repository wording (O1, R5), and record the fifth robustness case (R2).

## Not verified

* Repository settings and anything only the owner can see: description, topics, default workflow permissions, secret-scanning and
  vulnerability-reporting status, branch protection, collaborators.
* The text of issues, pull-request descriptions and comments (not part of the Git history; they are public after publishing).
* The upstream side of `NOTICE`: that each pinned commit exists and has the stated licence, whether utPLSQL ships a `NOTICE` file,
  and the current terms of Oracle Free, `postgres:16` and the AI providers.
* Whether the `claude.ai` session links in commit messages are viewable by outsiders.
* The README claims that need Oracle, PostgreSQL, an LLM or GitHub (marked above); the PostgreSQL case count rests on CI evidence.
* Whether GitHub Support can purge pull-request refs after a history rewrite.
* Dependency licences come from the installed package metadata, not from a licence-scanning tool.

## Commands

Run from the repository root. `S` is a scratch directory outside the repository.

```bash
# C0  all refs, including the pull-request heads (adds local refs under refs/audit/)
git fetch --all --prune && git fetch origin '+refs/pull/*/head:refs/audit/pull/*'
git rev-list --all | wc -l                     # 125
git rev-list origin/main | wc -l               # 24
# C1  the history as text (added lines are what could contain a secret)
git log --all -p -U0 --no-color --format='@@COMMIT %H' > $S/hist.txt
grep -a -E '^\+[^+]' $S/hist.txt | cut -c2- > $S/hist_added.txt
# C2  provider token prefixes and private keys, added lines of all history
grep -a -E '^\+' $S/hist.txt | grep -a -n -E 'sk-ant-|ghp_[A-Za-z0-9]{20,}|github_pat_|gh[ousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{12,}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{30,}'
# C3  password-like assignments with a value (review the output: placeholders only)
grep -a -E '^\+' $S/hist.txt | grep -a -i -E '(PASSWORD|PASSWD|PWD|SECRET|API_KEY|TOKEN)[A-Z_]*[ ]*[=:][ ]*[^ $"'"'"'{(]{3,}'
# C4  detect-secrets 1.5.0 on the tracked files
git ls-files -z | xargs -0 uvx detect-secrets scan > $S/ds_tree.json
# C5  detect-secrets on the history (run from the scratch directory; --all-files is required for untracked files)
(cd $S && uvx detect-secrets scan --all-files hist_added.txt > ds_hist.json)
printf 'aws_access_key_id = AKIA%s\n' "$(printf 'A%.0s' $(seq 1 16))" > $S/control.txt && (cd $S && uvx detect-secrets scan --all-files control.txt)   # control: 1+ findings
# C6  sensitive file names ever committed
git log --all --name-only --format= | sort -u | grep -i -E '(^|/)\.env($|\.)|\.pem$|\.key$|id_rsa|\.p12$|\.pfx$|credentials|secret|token'
# C7  the CI result branches
for b in ci-results/f3 ci-results/f5 ci-results/f5-differential; do git ls-tree -r --name-only origin/$b; done
git show origin/ci-results/f5:pytest.log | grep -n '/home/'
# C8  author and committer identities by type (do not print the addresses)
git log --all --format='%H%x1f%an%x1f%ae%x1f%cn%x1f%ce'          # classify %ae and %ce by domain
# C9  e-mail-shaped strings in content and messages (print domains/counts only)
grep -a -o -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' $S/hist_added.txt | sed -E 's/.*@/@/' | sort | uniq -c
git log --all --format=%B | grep -a -o -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' | sed -E 's/.*@/@/' | sort | uniq -c
# C10 paths, hosts and URLs in the tree
git grep -n -I -E '(/home/[a-z]|/mnt/[a-z]|/Users/[A-Za-z]|C:\\\\)' origin/main -- . ':!corpus' ':!uv.lock'
git grep -h -I -o -E 'https?://[A-Za-z0-9._-]+' origin/main -- . ':!corpus' ':!uv.lock' ':!tests/vendor' | sort | uniq -c | sort -rn
# C11 licence copies and provenance
sha1sum corpus/utplsql/LICENSE docs/benchmarks/data/LICENSE.utplsql corpus/oracle-db-sample-schemas/LICENSE tests/fixtures/testgen/hr/LICENSE corpus/logger/LICENSE tests/fixtures/testgen/logger/LICENSE
git ls-tree -r --name-only origin/main | grep -E '^corpus/' | sed -E 's|^corpus/([^/]+)/.*\.([A-Za-z]+)$|\1 .\2|' | sort | uniq -c
# C12 dependency licences and README commands (the make targets that write into docs/ were run in `git archive origin/main | tar -x -C $S/clone`)
uv run python -c "import importlib.metadata as m; [print(p, m.version(p), m.metadata(p).get('License-Expression') or m.metadata(p).get('License')) for p in ['typer','rich','pygments','hypothesis','pytest']]"
uv run plsql-lens bench -o $S/bench_copy        # after: cp -r docs/benchmarks/. $S/bench_copy ; diff -rq $S/bench_copy docs/benchmarks
(cd $S/clone && uv sync && make demo-f1 && make demo-f2 && diff -rq docs/reports/phase-2 <repo>/docs/reports/phase-2)
# C13 where 3afe6ea sits
git for-each-ref --contains 3afe6ea --format='%(refname)'; git rev-list origin/main ^3afe6ea | wc -l
# C14 the robustness claim
uv run pytest tests/robustness -m robustness -k never_raise_nor_hang -s
```
