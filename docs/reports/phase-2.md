# Phase F2 report — Review rules

Date: 2026-10-22. Branches `feat/f2-review-rules` → `feat/f2-outputs` → `feat/f2-llm` (stacked draft PRs
#2, #3, #4; nothing merged).

## What was built
* **ADR 0002** (`docs/adr/0002-statement-layer.md`): hybrid statement layer. The parser now emits flat
  `Stmt` records (kind, tokens, enclosing-construct context, BEGIN-block ids) on every body; rules are
  pure filters over them. Decided with a small measurement (token-scan prototype over the corpus)
  before writing code; the final layer reproduces the prototype's counts.
* **Rules PLL001–PLL007** (`src/plsql_lens/rules/`), contract and accepted false negatives in
  `docs/rules.md`.
* **Findings**: rule id, severity, `file:line:col`, message, rationale, fix hint, enclosing unit.
  Output: plain-text table (no new dependency), JSON, SARIF 2.1.0 (structural validation in a test, no
  network). Inline suppression `-- plsql-lens: disable=PLLnnn`: trailing comment, next code line, and
  whole subprogram when placed on its header line (cheap, so included).
* **CLI**: `plsql-lens review PATH [--format table|json|sarif] [--rules …] [-o OUT] [--explain …]`.
* **LLM layer**: `LLMProvider` with `claude-cli` (default), `anthropic-api` (needs `ANTHROPIC_API_KEY`,
  stdlib HTTPS) and `fake` (recorded responses). `--explain` attaches an explanation and patch to existing
  findings only; unusable or failed replies leave findings untouched. Tokens and cost reported by the backend
  are accumulated and printed/emitted (`llm_usage`).
* CI now enforces `--cov-fail-under=85` (F1 debt; coverage was already 93 %, now 94 %).
* `make demo-f2` → `docs/reports/phase-2/` (`review.txt|json|sarif` for `corpus/logger/logger.pkb`,
  `counts.md` over the corpus).

## Acceptance (SPEC §3 F2) — measured
| Criterion | Target | Measured |
|---|---|---|
| Fixtures per rule | ≥ 3 positive and ≥ 3 negative, green | 3 + 3 for each of 7 rules, all green (42 fixtures, 63 acceptance tests incl. 12 real corpus cases) |
| LLM layer tested with recorded responses | yes | yes: fake/injected transports only; no network or `claude` call in tests |
| CI | green on 3.11 and 3.13 | CI matrix (3.11 + 3.13) green on the code heads of all three PRs; the two intentionally-red test commits failed as expected; the last docs-only commit was still running when this was written |
| Coverage | ≥ 85 % | 94 % |
| Suite | — | 117 tests, ruff and `mypy --strict` clean |

Fixtures were written by Sonnet subagents from `docs/rules.md` only (they were told not to read the
implementation) and committed before the rules. All 7 rules passed on the first run; that is a weaker
signal than it sounds, because the fixtures are idealised near-misses (see FP review below for what real
code does).

## Findings per rule over the corpus (259 files, held-out reserve excluded)
| Rule | Severity | Findings |
|---|---|---|
| PLL001 | high | 6 |
| PLL002 | high | 27 |
| PLL003 | medium | 1 |
| PLL004 | medium | 12 |
| PLL005 | medium | 0 |
| PLL006 | low | 19 |
| PLL007 | info | 420 |

## Manual quality control (QC, not the F4 benchmark)
Seeded random sample (seed 42), ≤ 10 findings per rule (47 total), judged against `docs/rules.md` by a
Sonnet subagent that read only the PL/SQL; I checked every claimed FP myself.

| Rule | Sampled | TP | TP-benign | FP |
|---|---|---|---|---|
| PLL001 | 6 | 2 | 4 | 0 |
| PLL002 | 10 | 3 | 7 | 0 |
| PLL003 | 1 | 0 | 1 | 0 |
| PLL004 | 10 | 4 | 5 | **1** |
| PLL005 | 0 | – | – | – |
| PLL006 | 10 | 0 | 6 | **4** |
| PLL007 | 10 | 2 | 8 | 0 |

"TP-benign" = the contract holds but a reviewer would shrug (e.g. `is_number` idiom, a batch `COMMIT` every
N files, constants concatenated into SQL). Confirmed false positives (5), **left unfixed on purpose** so F4's
"before" baseline is the first rule version:
* **PLL004** `coe_v3.sql:160`: `SELECT NVL(MAX(x),0)+1 INTO …` — the aggregate is nested inside `NVL`, and
  the always-one-row exemption only looks at depth 0. Also not exempt but harmless: `LISTAGG`/`XMLAGG` selects.
* **PLL006** `logger.pkb:555,559,561,563`: `p_date_stop-p_date_start < 14` — the "simple operand" check does
  not reject an operand adjacent to an arithmetic operator, so it pairs a DATE parameter with a numeric literal.
* PLL006 also reports 6 harmless VARCHAR2-vs-number comparisons (`ut_utils.pkb`, values extracted as text).

Reading: PLL001/002/003 precision looks acceptable (no FPs; benign share is high, i.e. they are "worth a
look" rules); PLL006 is the weakest (4 FP + 6 benign of 10, 0 clearly useful); PLL007 is noisy by design
(`info`). PLL005 found nothing in this corpus, so its real-world recall is **unmeasured** (only fixtures).

## Held-out reserve
`tests/heldout/` holds 5 corpus files hand-labelled from the contract before the rules existed
(labels never compared with rule output; do not tune on them; F4 measures). Weakness: the corpus offers
little material for PLL001/003–006, so the reserve is almost all PLL002/PLL007 labels (PLL001: 0, PLL003: 0,
PLL004: 0, PLL005: 0, PLL006: 0). Meaningful held-out precision/recall for those needs F4's seeded-defect
corpus. Rule output on the reserve was never inspected (the two later files were chosen by finding-count
per file only).

## LLM layer: real smoke call (outside CI)
One `claude -p` call (haiku 5.5) explaining a PLL001 fixture finding: `docs/reports/llm_smoke_f2.json`.
Reported: 40 715 input tokens (almost all CLI/session context, not our prompt), 400 output tokens,
**USD 0.0031**. Takeaway for F3/F4: with the `claude-cli` backend each call carries ~40 k tokens of CLI
overhead; batching prompts or the API backend will matter for cost. Model ids/pricing were not re-confirmed
beyond this reported cost.

## Known limits
* Rule limits are listed in `docs/rules.md` (no type resolution, PLL007 context-blind, PLL002 intra-subprogram
  only, PLL005 cursor loops only, `$IF` both branches analysed).
* PLL007 does not scan declaration sections; type bodies count as one unit.
* Suppression by comment uses a line regex: a directive inside a string literal would be honoured.
* The parser's statement layer flattens `DECLARE` sections and does not parse expressions.
* `claude-cli` backend cost is only as accurate as what the CLI reports; `anthropic-api` reports tokens only.

## Demo
```bash
make demo-f2   # review corpus/logger/logger.pkb as table/json/sarif + per-rule counts
uv run plsql-lens review tests/fixtures/rules/PLL001/pos_1.pkb --explain --explain-max 1
```

## Spend (estimate — `/cost` is not readable from inside the session)
Rough estimate from token volume: lead ≈ 3–4 USD, six Sonnet subagent runs (fixtures ×2, held-out labelling
×2, QC review, plus the resumed F1 labeler is not counted here) ≈ 3–4 USD, LLM smoke call 0.003 USD.
**≈ 6–8 USD against the 12 USD budget (projected ceiling 15 USD never approached); reserve untouched.**
**Measured (2026-10-22):** the cloud credit balance went from 69 to 59 USD across F1 and F2 together,
so F1 + F2 cost **10 USD** against a combined budget of 21 USD (estimates added up to 11–14 USD).
The balance cannot be split per phase.

## Left for F3 / F4
* F3: utPLSQL generation + execution (Docker availability to be verified first).
* F4: seeded-defect corpus and scorer (the real precision/recall); tuned "after" rules, starting from the 5
  FPs above and the benign classes; held-out reserve evaluation; LLM-only baseline.
* Open decisions for you: whether to merge PRs in order #2 → #3 → #4 (stacked bases), and whether F4 should
  treat TP-benign as TP or as noise in its metrics.
