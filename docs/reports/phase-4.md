# Phase F4 report — Benchmark

Date: 2026-10-23. Branch `feat/f4-benchmark`, one draft PR based on `origin/main` @ `67afb855…` (the "before" rules).

## What was built
* `src/plsql_lens/bench/`: seeded deterministic **generator** (templates → standalone packages and real-corpus
  injections, with a manifest of regions and expected lines), **scorer** (TP/FP/FN definition in
  `docs/benchmarks/README.md`), Wilson intervals, engine runner ("before" exported from git, "after" = current),
  report renderer, LLM-baseline harness. CLI: `plsql-lens bench [--seed N] [--split dev|test|both] [-o DIR]`,
  `plsql-lens bench-llm`. Scorer/generator tests were committed red first.
* **Ground truth**: 4 template sets (`dev`, `test` × base + hard) written by Sonnet subagents from `docs/rules.md`
  only; 10 defect + 10 hard-negative variants per rule and split; 50 defect + 50 negative instances per rule and
  split (PLL005 included); `dev` and `test` differ in templates, style, seed and corpus base files.
* `test` split frozen and sealed in git **before any tuning**; SHA-256 in `docs/benchmarks/seal.json`, enforced by
  `make bench` and by a unit test. One re-seal is disclosed (generator fix, engine never run on `test`).
* `docs/benchmarks/` (README with methodology and threats, results.md, raw JSON, data, actionable rate sample,
  LLM baseline recordings). `make bench` twice → identical output (`diff -r` clean).

## Headline (frozen `test` split; full tables in `docs/benchmarks/results.md`)
| | TP / FP / FN | Precision | Recall | F1 |
|---|---|---|---|---|
| Rules **before** (F2+F3) | 464 / 0 / 1 | 1.000 [0.99–1.00] | 0.998 [0.99–1.00] | 0.999 |
| Rules **after** (tuned on `dev`) | 464 / 0 / 1 | 1.000 [0.99–1.00] | 0.998 [0.99–1.00] | 0.999 |

Per rule and for `dev` (where tuning shows: PLL006 precision 0.909 → 1.000, 5 FP → 0) see results.md.
**Honest reading:** on `test` the tuning changes nothing, and both rule versions are near-perfect; the benchmark
confirms the rules implement their contract across 20 syntactic variants per rule, it does not show they are
good at finding defects in the wild (ceiling effect, circularity: see threats to validity).

## Other measurements
* **Real corpus, F2 → now** (259 files): 16 findings removed, 0 added — PLL004 12 → 9, PLL006 19 → 13,
  PLL007 420 → 413 (raw counts). The 5 known F2 false positives are gone (coe_v3.sql:160; logger.pkb:555–563)
  plus 6 further PLL006 and 7 PLL007 `''''` false positives. **Lost F2 true positives:** two PLL004 findings in
  `ut_suite_tag_filter.pkb` (lines 61, 67; `LISTAGG` selects, "TP-benign" in F2) are now exempt because the
  contract was widened to LISTAGG; no other F2 TP was lost.
* **F2 held-out reserve** (5 files, 97 labeled spans): 97 / 0 / 0 before and after.
* **Actionable rate** (hand-labeled by the session, 59 sampled real-corpus findings): PLL001 0/6, PLL002 3/15
  (0.20 [0.07–0.45]), PLL003 0/1, PLL004 0/9, PLL006 0/13, PLL007 0/15 (one was a false positive, fixed);
  PLL005 had no findings. Almost every finding is contract-correct but harmless in context (probe idioms,
  program-built identifiers, batch commits). Rubric and caveats in `docs/benchmarks/`.
* **LLM-only baseline** (40 `test` files, Sonnet via `claude-cli`, no engine): 203 / 0 / 0 against the
  seeded ground truth, rules on the same files 202 / 0 / 1 — the LLM is as good as the rules on this ground truth
  (the ground truth was also written by an LLM). Cost **1.13 USD** (projection from a 4-file probe: 1.3–1.4 USD, cap 2).

## What was tuned and why
PLL004: aggregates nested in expressions, `LISTAGG`, not analytic/scalar-subquery/`HAVING` (F2 FP `NVL(MAX(x),0)+1`);
PLL006: no comparison when an operand belongs to an arithmetic/`||` expression (F2 FP `p_stop - p_start < 14`, and the
dev `l_end - l_start < 3` negative); PLL007: `''''` is one quote character (found by labeling real findings, after
the dev tuning; test untouched). Contract updated in `docs/rules.md`; tests in `tests/unit/test_rules_tuning.py`
(written red first, except the PLL007 case, written together with its fix).

## Known gaps
* Ceiling effect and shared-author circularity (see README); `test` does not exercise the tuned constructs.
* Generator flaw: bases ending in an initialization block get snippets inside it (3 of 35 injected `test` files;
  explains the one PLL005 FN). Sealed data left as is; documented.
* The actionable sample is small, single-labeler, strict; PLL001/003 have 6/1 findings, PLL005 none on the corpus.
* PLL002 still flags concatenations guarded by `DBMS_ASSERT` through a variable (contract: only direct calls).
* The "before" run needs full git history (CI checkout now uses `fetch-depth: 0`).

## Demo
```bash
make bench       # regenerate splits, run before/after, write docs/benchmarks/{results.md,raw,data}; no LLM
make bench-llm   # re-run the LLM-only baseline — COSTS MONEY (capped at 2 USD)
```

## Spend (against 14 USD)
* **LLM baseline: 1.13 USD** (measured by the CLI) + 0.13 USD probe = 1.27 USD.
* Whole session: `get_session` reports a cumulative `usage.cost_usd` of **25.86 USD** for F1–F4 so far (lead session;
  the meter cannot be split per phase and I do not know whether subagents are included). F1 + F2 were measured by the
  credit balance at 10 USD; F3 was not measured. Subtracting, F4 so far is roughly 6–13 USD depending on F3's real
  cost, **best guess ≈ 10 USD** including five Sonnet subagent runs (four template writers, one labeler). This is an
  estimate, not a measurement; please compare with your credit balance. No reserve used.
* **Measured (2026-10-22):** the cloud credit balance went from 50 to 37 USD during F4, so F4 cost **13 USD**
  against its 14 USD budget, including the LLM baseline. The session meter (25.86 USD cumulative) undercounted.
