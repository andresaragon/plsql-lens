"""Orchestration: generate a split, run before/after, score, write raw results."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .config import BEFORE_SHA, SEEDS, base_files
from .engine import run_before, run_engine
from .extras import corpus_delta, corpus_files, heldout_manifest
from .generate import generate, manifest_hash
from .model import Found, Manifest
from .score import score


class SealError(RuntimeError):
    pass


def _fl(findings: list[Found]) -> list[list[object]]:
    return [
        [f.file, f.rule, f.line]
        for f in sorted(set(findings), key=lambda f: (f.file, f.line, f.rule))
    ]


def item_counts(m: Manifest) -> dict[str, Any]:
    out: dict[str, Any] = {"files": len(m.files), "standalone": 0, "injected": 0}
    for kind in m.files.values():
        out[kind] += 1
    per: dict[str, dict[str, int]] = {}
    for r in m.regions:
        d = per.setdefault(r.rule, {"defect_regions": 0, "defect_spans": 0, "negatives": 0})
        if r.kind == "defect":
            d["defect_regions"] += 1
            d["defect_spans"] += len(r.expected)
        else:
            d["negatives"] += 1
    out["per_rule"] = dict(sorted(per.items()))
    return out


def run_split(
    root: Path, out: Path, split: str, seed: int | None = None, before_sha: str = BEFORE_SHA
) -> dict[str, Any]:
    seed = SEEDS[split] if seed is None else seed
    data = out / "data" / split
    m = generate(split, seed, data, base_files=base_files(root, split), base_root=root)
    digest = manifest_hash(m)
    seal_path = out / "seal.json"
    if (
        seal_path.exists()
        and split in (seals := json.loads(seal_path.read_text()))
        and seed == SEEDS[split]
    ):
        if seals[split] != digest:
            raise SealError(f"{split} manifest hash {digest} != sealed {seals[split]}")
    before = run_before(before_sha, root, data)
    after = run_engine(data)
    raw = {
        "split": split,
        "seed": seed,
        "manifest_sha256": digest,
        "before_sha": before_sha,
        "items": item_counts(m),
        "before": score(m, before).to_dict(),
        "after": score(m, after).to_dict(),
        "findings_before": _fl(before),
        "findings_after": _fl(after),
    }
    (out / "raw").mkdir(parents=True, exist_ok=True)
    (out / "raw" / f"{split}.json").write_text(json.dumps(raw, indent=1, sort_keys=True) + "\n")
    return raw


def run_extras(root: Path, out: Path, before_sha: str = BEFORE_SHA) -> None:
    files = corpus_files(root)
    before = run_before(before_sha, root, root, files)
    after = run_engine(root, files)
    delta = corpus_delta(before, after)
    delta["files"] = len(files)
    h = heldout_manifest(root)
    held_files = sorted(h.files)
    hb = run_before(before_sha, root, root, held_files)
    ha = run_engine(root, held_files)
    heldout = {"before": score(h, hb).to_dict(), "after": score(h, ha).to_dict()}
    (out / "raw").mkdir(parents=True, exist_ok=True)
    (out / "raw" / "corpus.json").write_text(json.dumps(delta, indent=1, sort_keys=True) + "\n")
    (out / "raw" / "heldout.json").write_text(json.dumps(heldout, indent=1, sort_keys=True) + "\n")


def _subset(m: Manifest, files: set[str]) -> Manifest:
    return Manifest(
        m.split, m.seed, {f: k for f, k in m.files.items() if f in files},
        [r for r in m.regions if r.file in files],
    )  # fmt: skip


def run_llm_scoring(out: Path) -> dict[str, Any] | None:
    """Score the recorded LLM-only baseline and the engine on the same sample of test files."""
    from .llm_baseline import findings_from_recording

    rec_path = out / "llm_baseline" / "responses.json"
    raw_path = out / "raw" / "test.json"
    if not rec_path.exists() or not raw_path.exists():
        return None
    rec = json.loads(rec_path.read_text())
    raw = json.loads(raw_path.read_text())
    m = Manifest.load(out / "data" / "test" / "manifest.json")
    files = set(rec["responses"])
    sub = _subset(m, files)
    llm = findings_from_recording(rec)
    eng_b = [Found(*f) for f in raw["findings_before"] if f[0] in files]
    eng_a = [Found(*f) for f in raw["findings_after"] if f[0] in files]
    resp = rec["responses"].values()
    res = {
        "model": rec["model"],
        "files": len(files),
        "items": item_counts(sub),
        "llm": score(sub, llm).to_dict(),
        "engine_before": score(sub, eng_b).to_dict(),
        "engine_after": score(sub, eng_a).to_dict(),
        "input_tokens": sum(r["input_tokens"] for r in resp),
        "output_tokens": sum(r["output_tokens"] for r in resp),
        "cost_usd": round(sum(r["cost_usd"] or 0.0 for r in resp), 6),
        "errors": sum(1 for r in resp if "error" in r),
    }
    (out / "raw" / "llm_baseline.json").write_text(json.dumps(res, indent=1, sort_keys=True) + "\n")
    return res


def run_actionable(out: Path) -> dict[str, Any] | None:
    """Aggregate the hand-labeled sample of real-corpus findings into per-rule counts."""
    p = out / "actionable" / "labels.json"
    s = out / "actionable" / "sample.json"
    if not p.exists() or not s.exists():
        return None
    labels = json.loads(p.read_text())["labels"]
    totals = json.loads(s.read_text())["totals"]
    per: dict[str, dict[str, int]] = {}
    for e in labels:
        d = per.setdefault(
            e["rule"], {"sampled": 0, "contract_holds": 0, "actionable": 0, "total_findings": 0}
        )
        d["sampled"] += 1
        d["contract_holds"] += bool(e["contract_holds"])
        d["actionable"] += bool(e["actionable"])
    for r, d in per.items():
        d["total_findings"] = totals.get(r, 0)
    res = {
        "note": "Labeled by the working session (a Sonnet subagent following docs/benchmarks/actionable/RUBRIC.md, "
        "spot-checked by the lead), not by the code's maintainers. Sample: seed 4004, at most 15 findings per rule, "
        "current rules, real corpus.",
        "per_rule": dict(sorted(per.items())),
    }
    (out / "raw").mkdir(parents=True, exist_ok=True)
    (out / "raw" / "actionable.json").write_text(json.dumps(res, indent=1, sort_keys=True) + "\n")
    return res
