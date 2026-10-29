"""Render docs/benchmarks/results.md from the raw JSON files (deterministic)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .model import RULE_IDS
from .stats import wilson


def _f(x: float | None) -> str:
    return "n/a" if x is None else f"{x:.3f}"


def _m(d: dict[str, Any], key: str) -> str:
    v, ci = d.get(key), d.get(f"{key}_ci")
    if v is None or ci is None:
        return "n/a"
    return f"{v:.3f} [{ci[0]:.2f}–{ci[1]:.2f}]"


def _load(out: Path, name: str) -> dict[str, Any] | None:
    p = out / "raw" / name
    return json.loads(p.read_text()) if p.exists() else None


def split_section(raw: dict[str, Any], title: str) -> list[str]:
    items = raw["items"]["per_rule"]
    lines = [f"### {title}", "",
             f"Manifest SHA-256 `{raw['manifest_sha256']}` · seed {raw['seed']} · "
             f"{raw['items']['files']} files ({raw['items']['standalone']} standalone, "
             f"{raw['items']['injected']} injected)", ""]  # fmt: skip
    lines += ["| Rule | Defect spans (regions) | Hard negatives | Before TP/FP/FN | After TP/FP/FN |",
              "|---|---|---|---|---|"]  # fmt: skip
    for r in (*RULE_IDS, "total"):
        if r == "total":
            b, a = raw["before"]["total"], raw["after"]["total"]
            spans = sum(v["defect_spans"] for v in items.values())
            regs = sum(v["defect_regions"] for v in items.values())
            negs = sum(v["negatives"] for v in items.values())
            name = "**all**"
        else:
            b, a = raw["before"]["per_rule"][r], raw["after"]["per_rule"][r]
            v = items.get(r, {"defect_spans": 0, "defect_regions": 0, "negatives": 0})
            spans, regs, negs, name = v["defect_spans"], v["defect_regions"], v["negatives"], r
        lines.append(f"| {name} | {spans} ({regs}) | {negs} | {b['tp']}/{b['fp']}/{b['fn']} "
                     f"| {a['tp']}/{a['fp']}/{a['fn']} |")  # fmt: skip
    lines += ["", "| Rule | Precision before | Precision after | Recall before | Recall after | F1 before | F1 after |",
              "|---|---|---|---|---|---|---|"]  # fmt: skip
    for r in (*RULE_IDS, "total"):
        b = raw["before"]["total"] if r == "total" else raw["before"]["per_rule"][r]
        a = raw["after"]["total"] if r == "total" else raw["after"]["per_rule"][r]
        lines.append(f"| {'**all**' if r == 'total' else r} | {_m(b, 'precision')} | {_m(a, 'precision')} "
                     f"| {_m(b, 'recall')} | {_m(a, 'recall')} | {_m(b, 'f1')} | {_m(a, 'f1')} |")  # fmt: skip
    lines += ["", f"Not scored: background findings in injected files before/after "
              f"{raw['before']['background_findings']}/{raw['after']['background_findings']}; cross-rule findings "
              f"inside labeled regions {raw['before']['cross_rule_findings']}/{raw['after']['cross_rule_findings']}.", ""]  # fmt: skip
    return lines


def _external_section(out: Path) -> list[str]:
    """Compact comparison on the external-author split (F4b); empty unless its raw engine run exists."""
    ext = out / "external"
    manifest, engine = ext / "data" / "manifest.json", ext / "raw" / "engine.json"
    if not (manifest.exists() and engine.exists()):
        return []
    from .external import ExternalManifest, apply_adjudication, evaluate
    from .llm_baseline import findings_from_recording
    from .model import Found
    from .stats import prf

    m = ExternalManifest.load(manifest)
    runs: list[tuple[str, list[Found], str]] = []
    before = ext / "raw" / "engine_before.json"
    if before.exists():
        raw = json.loads(before.read_text())
        runs.append(
            (
                f"Rules (before, {raw['before_sha'][:7]})",
                [Found(*f) for f in raw["findings"]],
                "before",
            )
        )
    raw = json.loads(engine.read_text())
    runs.append(("Rules (frozen)", [Found(*f) for f in raw["findings"]], "engine"))
    llm = ext / "llm_baseline" / "responses.json"
    if llm.exists():
        runs.append(("LLM only", findings_from_recording(json.loads(llm.read_text())), "llm"))

    def totals(counts: dict[str, dict[str, int]]) -> dict[str, int]:
        return {k: sum(c[k] for c in counts.values()) for k in ("tp", "fp", "fn")}

    L = ["## External-author split (F4b)", "",
         f"Cross-author check on {len(m.cases)} cases written by Gemini whose markers Claude revised, sealed before "
         "any run: **not a human gold standard**, and 40 short cases give wide intervals. Rules were never tuned on "
         "it. Per-rule tables, the adjudication and its limits: [external/results.md](external/results.md).", "",
         "| Method | Strict TP/FP/FN | Precision | Recall | Adjudicated TP/FP/FN (provisional) |",
         "|---|---|---|---|---|"]  # fmt: skip
    for name, found, who in runs:
        score = evaluate(m, found)
        d = ext / "adjudication" / f"{who}.json"
        decisions = json.loads(d.read_text())["decisions"] if d.exists() else []
        s, a = totals(score.per_rule), totals(apply_adjudication(score, decisions))
        p = prf(s["tp"], s["fp"], s["fn"])
        L.append(f"| {name} | {s['tp']}/{s['fp']}/{s['fn']} | {_m(p, 'precision')} | {_m(p, 'recall')} "
                 f"| {a['tp']}/{a['fp']}/{a['fn']} |")  # fmt: skip
    return L + [""]


def render_results(out: Path) -> str:
    test, dev = _load(out, "test.json"), _load(out, "dev.json")
    corpus, held = _load(out, "corpus.json"), _load(out, "heldout.json")
    llm, act = _load(out, "llm_baseline.json"), _load(out, "actionable.json")
    L: list[str] = ["# Benchmark results", "",
                    "Generated by `make bench` from the raw JSON in `raw/`; do not edit by hand. "
                    "Definitions, splits and threats to validity: [README.md](README.md). "
                    "Intervals are 95 % Wilson score intervals.", ""]  # fmt: skip
    if test:
        L += ["## Held-out `test` split (frozen)", ""]
        L += [
            f'"Before" = rules at commit `{test["before_sha"]}`; "after" = current rules, tuned on `dev` only.',
            "",
        ]
        L += split_section(test, "test")
    if dev:
        L += ["## `dev` split (used for tuning; reference only)", ""] + split_section(dev, "dev")
    if corpus:
        L += ["## Real corpus: what changed", "",
              f"{corpus['files']} corpus files (held-out reserve excluded).", "",
              "| Rule | Before | After |", "|---|---|---|"]  # fmt: skip
        for r in RULE_IDS:
            L.append(f"| {r} | {corpus['before_counts'][r]} | {corpus['after_counts'][r]} |")
        L += [
            "",
            f"Findings removed by tuning: {len(corpus['removed'])}; added: {len(corpus['added'])}.",
            "",
        ]
        for kind in ("removed", "added"):
            if corpus[kind]:
                L += [f"<details><summary>{kind} ({len(corpus[kind])})</summary>", ""]
                L += [f"* `{f}:{ln}` {r}" for f, r, ln in corpus[kind]] + ["", "</details>", ""]
    if held:
        L += ["## F2 held-out reserve (5 hand-labeled corpus files)", "",
              "| | TP/FP/FN | Precision | Recall |", "|---|---|---|---|"]  # fmt: skip
        for k in ("before", "after"):
            t = held[k]["total"]
            L.append(
                f"| {k} | {t['tp']}/{t['fp']}/{t['fn']} | {_m(t, 'precision')} | {_m(t, 'recall')} |"
            )
        L.append("")
    if act:
        L += ["## Actionable rate (real corpus, hand-labeled sample)", "",
              act.get("note", ""), "", "| Rule | Findings in corpus (unique lines) | Sampled | Contract holds | Actionable | Rate (95 % Wilson) |",
              "|---|---|---|---|---|---|"]  # fmt: skip
        for r in RULE_IDS:
            a = act["per_rule"].get(r)
            if a and a["sampled"]:
                lo, hi = wilson(a["actionable"], a["sampled"])
                L.append(
                    f"| {r} | {a['total_findings']} | {a['sampled']} | {a['contract_holds']} "
                    f"| {a['actionable']} | {a['actionable'] / a['sampled']:.3f} [{lo:.2f}–{hi:.2f}] |"
                )
            else:
                L.append(f"| {r} | 0 | 0 | – | – | n/a |")
        L.append("")
    if llm:
        L += ["## LLM-only baseline (contrast)", "",
              f"Model `{llm['model']}`, {llm['files']} files sampled from `test` by seed, no access to the rule engine. "
              f"Cost **{llm['cost_usd']:.4f} USD** ({llm['input_tokens']} in / {llm['output_tokens']} out tokens, "
              f"{llm['errors']} failed calls).", "",
              "| Method (same files) | TP/FP/FN | Precision | Recall | F1 |", "|---|---|---|---|---|"]  # fmt: skip
        for name, key in (
            ("LLM only", "llm"),
            ("Rules before", "engine_before"),
            ("Rules after", "engine_after"),
        ):
            t = llm[key]["total"]
            L.append(
                f"| {name} | {t['tp']}/{t['fp']}/{t['fn']} | {_m(t, 'precision')} | {_m(t, 'recall')} | {_m(t, 'f1')} |"
            )
        L += [
            "",
            "| Rule | LLM P | LLM R | Rules-after P | Rules-after R |",
            "|---|---|---|---|---|",
        ]
        for r in RULE_IDS:
            a, e = llm["llm"]["per_rule"][r], llm["engine_after"]["per_rule"][r]
            L.append(
                f"| {r} | {_m(a, 'precision')} | {_m(a, 'recall')} | {_m(e, 'precision')} | {_m(e, 'recall')} |"
            )
        L.append("")
    L += _external_section(out)
    return "\n".join(L).rstrip() + "\n"
