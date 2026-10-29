# Phase F4b report — external-author split

Date: 2026-10-26. Branch `feat/f4b-external-split` (one draft PR on current `main` @ `6c2982c`).

> The prompt file named in the request (`PL-SQL Lens - Prompt F4b (nube).md`, in the owner's Obsidian vault) is not
> reachable from the cloud session, so I worked from the seven-step order in the request and from the F4b plan written in
> `docs/benchmarks/external/README.md` and `docs/benchmarks/human/README.md`. If the prompt has requirements beyond those
> (a budget, extra deliverables), they are not reflected here.

## What was done, in the requested order
1. **Reference rules frozen** — `docs/benchmarks/external/frozen.json` (parser, rules and contract hashes at `6c2982c`), enforced by `tests/unit/test_external_frozen.py`.
2. **Converter and evaluator, on synthetic data** — `src/plsql_lens/bench/external.py` (+ `external_run.py`, CLI `bench-external convert|run|llm|report`); tests written red first.
3. **Seal commit** `d2755f2` before any real execution: manifest SHA-256 `5f1e1eee…f11f` in `docs/benchmarks/seal.json`.
4. **Engine executed once** on the sealed cases (second run refused by the tool).
5. **LLM-only baseline** (Sonnet, 40 files): 0.596 USD, 132 834 in / 6 481 out tokens, 0 failed calls.
6. **Strict table + adjudicated table** (adjudicated: *provisional (Claude), pending your review*).
7. This report and the draft PR.

## Result (40 cases; 64 `expect`, 60 `clean`, 9 `beyond` markers)
| | Strict TP/FP/FN | Precision | Recall | Adjudicated TP/FP/FN (provisional) |
|---|---|---|---|---|
| Rules (frozen @ `6c2982c`) | 64 / 2 / 0 | 0.970 [0.90–0.99] | 1.000 [0.94–1.00] | 65 / 1 / 0 |
| LLM only (contract, no engine) | 64 / 2 / 0 | 0.970 [0.90–0.99] | 1.000 [0.94–1.00] | 65 / 1 / 0 |

Per-rule tables, intervals and the `beyond` figure (0 of 9 for both) are in `docs/benchmarks/external/results.md`.
Both methods produced the **same two** unmarked findings, so one adjudication serves both: `e023:17` PLL004 (a real
contract defect the author missed → TP) and `e037:43` PLL002 (a `DBMS_ASSERT`-guarded variable concatenation: safe code,
documented limit of the contract → stays an FP; it is also the only `clean` trap that fired). No marker was found wrong;
no `expect` was missed by either method.

## Honest reading
The external split is **not** harder than the seeded one for these rules: the rules and a contract-prompted LLM tie at
~0.97–0.99 precision and recall 1.0. The informative numbers are the ones the contract cannot reach: `beyond` recall 0/9 for
both, and the one DBMS_ASSERT-through-a-variable false positive. Ground truth is a Gemini-authored split whose markers Claude
revised against the same contract (7 markers, documented), and the baseline is a Claude model, so the split is a
cross-author check, not a human gold standard. 40 short cases give wide intervals (precision lower bound 0.90 overall,
0.57–0.72 per rule).

## Known gaps
* The adjudication is the working session's, not an independent person's; two decisions only, both argued in the JSON.
* `beyond` is 9 markers; no statistical statement about real-world recall is possible.
* The human-written split is still pending. No rule was tuned on this split.

## Demo
```bash
uv run plsql-lens bench-external convert     # verifies the seal (no engine, no LLM)
uv run plsql-lens bench-external report      # re-renders results.md from the recorded runs
```

## Spend (against an unknown budget — see the note at the top)
LLM baseline **0.596 USD** (measured by the CLI). Session meter (`get_session`): 25.86 USD when I closed F4, 32.54 USD now
→ **≈ 6.7 USD for this phase** by meter difference (it includes the baseline; not split further; an estimate — your credit
balance is the reference). No reserve used.
