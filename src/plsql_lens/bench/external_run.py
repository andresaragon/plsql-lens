"""Steps of the external-split evaluation (F4b): convert/seal, run once, LLM baseline, report."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from ..llm import LLMError, LLMProvider
from .config import BEFORE_SHA
from .engine import run_before, run_engine
from .external import (
    ExternalManifest,
    apply_adjudication,
    convert,
    evaluate,
    manifest_hash,
    render_tables,
)
from .llm_baseline import build_prompt, findings_from_recording

BASE = Path("docs/benchmarks/external")


class ExternalError(RuntimeError):
    pass


def check_frozen(root: Path) -> str:
    """Abort unless parser, rules and contract still match docs/benchmarks/external/frozen.json."""
    frozen = json.loads((root / BASE / "frozen.json").read_text())
    current = {k: hashlib.sha256((root / k).read_bytes()).hexdigest() for k in frozen["files"]}
    if current != frozen["files"]:
        raise ExternalError("engine or contract differ from the frozen reference rules")
    return str(frozen["frozen_at_commit"])


def do_convert(root: Path, seal: bool = False) -> str:
    """Regenerate the marker-free data; verify (or, with ``seal``, record) the manifest hash."""
    m = convert(root / BASE / "cases", root / BASE / "data")
    digest = manifest_hash(m)
    seal_path = root / "docs" / "benchmarks" / "seal.json"
    seals = json.loads(seal_path.read_text())
    if seal:
        seals["external"] = digest
        seal_path.write_text(json.dumps(seals, indent=1) + "\n")
    elif seals.get("external") != digest:
        raise ExternalError(f"external manifest hash {digest} != sealed {seals.get('external')}")
    return digest


def do_run(root: Path, force: bool = False) -> dict[str, Any]:
    """Run the frozen engine over the converted cases. Refuses to run twice (the point is one run)."""
    out = root / BASE / "raw" / "engine.json"
    if out.exists() and not force:
        raise ExternalError(f"{out} exists: the engine is executed once on this split")
    commit = check_frozen(root)
    do_convert(root)  # re-verifies the seal
    m = ExternalManifest.load(root / BASE / "data" / "manifest.json")
    findings = run_engine(root / BASE / "data", [c.file for c in m.cases])
    res = {
        "frozen_at_commit": commit,
        "manifest_sha256": manifest_hash(m),
        "findings": sorted({(f.file, f.rule, f.line) for f in findings}),
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(res, indent=1, sort_keys=True) + "\n")
    return res


def do_run_before(
    root: Path,
    force: bool = False,
    sha: str = BEFORE_SHA,
    repo: Path | None = None,
    runner: Any = run_before,
) -> dict[str, Any]:
    """Run the "before" rules (``sha``, F4's BEFORE_SHA) ONCE over the sealed, converted cases.

    The "before" rules are an immutable git commit, so the frozen-file check of the "after" rules does not
    apply; the seal of the split is still verified. Nothing is tuned: this only measures what F4's tuning on
    ``dev`` did on a split it never saw.
    """
    out = root / BASE / "raw" / "engine_before.json"
    if out.exists() and not force:
        raise ExternalError(f"{out} exists: the 'before' rules are executed once on this split")
    do_convert(root)  # re-verifies the seal
    m = ExternalManifest.load(root / BASE / "data" / "manifest.json")
    findings = runner(sha, repo or root, root / BASE / "data", [c.file for c in m.cases])
    res = {
        "before_sha": sha,
        "manifest_sha256": manifest_hash(m),
        "findings": sorted({(f.file, f.rule, f.line) for f in findings}),
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(res, indent=1, sort_keys=True) + "\n")
    return res


def do_llm(root: Path, provider: LLMProvider, model: str, max_usd: float) -> dict[str, Any]:
    do_convert(root)
    m = ExternalManifest.load(root / BASE / "data" / "manifest.json")
    responses: dict[str, dict[str, Any]] = {}
    spent = 0.0
    for c in m.cases:
        prompt = build_prompt(root, c.file, (root / BASE / "data" / c.file).read_text())
        try:
            r = provider.complete(prompt)
            responses[c.file] = {"text": r.text, "input_tokens": r.input_tokens,
                                 "output_tokens": r.output_tokens, "cost_usd": r.cost_usd}  # fmt: skip
            spent += r.cost_usd or 0.0
        except LLMError as e:
            responses[c.file] = {
                "error": str(e),
                "input_tokens": 0,
                "output_tokens": 0,
                "cost_usd": 0.0,
            }
        if spent > max_usd:
            break
    rec = {"model": model, "responses": responses}
    out = root / BASE / "llm_baseline" / "responses.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(rec, indent=1, sort_keys=True) + "\n")
    return rec


def _decisions(root: Path, who: str) -> list[dict[str, Any]]:
    p = root / BASE / "adjudication" / f"{who}.json"
    return json.loads(p.read_text())["decisions"] if p.exists() else []


def do_report(root: Path) -> str:
    """Render docs/benchmarks/external/results.md from the recorded runs and adjudications."""
    from .model import Found

    m = ExternalManifest.load(root / BASE / "data" / "manifest.json")
    eng = json.loads((root / BASE / "raw" / "engine.json").read_text())
    engine_found = [Found(*f) for f in eng["findings"]]
    sections = ["# External split — results", "",
                f"Frozen reference rules: commit `{eng['frozen_at_commit']}`. Manifest SHA-256 `{eng['manifest_sha256']}`. "
                f"{len(m.cases)} cases. Rules were never tuned on this split.", ""]  # fmt: skip
    prov = (root / BASE / "adjudication" / "engine.json").exists()
    es = evaluate(m, engine_found)
    sections.append(
        render_tables(
            "Rules (frozen)", es, apply_adjudication(es, _decisions(root, "engine")), prov
        )
    )
    before_path = root / BASE / "raw" / "engine_before.json"
    if before_path.exists():
        bef = json.loads(before_path.read_text())
        bs = evaluate(m, [Found(*f) for f in bef["findings"]])
        after_set = {tuple(f) for f in eng["findings"]}
        before_set = {tuple(f) for f in bef["findings"]}
        sections.append(
            f'Before rules: `src/plsql_lens/` at commit `{bef["before_sha"]}` (F4\'s "before", prior to the tuning '
            f"on `dev`), run once on the same sealed cases. Findings only in before: {len(before_set - after_set)}; "
            f"only in after: {len(after_set - before_set)}. Not tuned on this split either.\n"
        )
        sections.append(
            render_tables(
                f"Rules (before, {bef['before_sha'][:7]})",
                bs,
                apply_adjudication(bs, _decisions(root, "before")),
                (root / BASE / "adjudication" / "before.json").exists(),
            )  # fmt: skip
        )
    llm_path = root / BASE / "llm_baseline" / "responses.json"
    if llm_path.exists():
        rec = json.loads(llm_path.read_text())
        ls = evaluate(m, findings_from_recording(rec))
        cost = sum(r.get("cost_usd") or 0.0 for r in rec["responses"].values())
        sections.append(
            f"LLM-only baseline: `{rec['model']}`, {len(rec['responses'])} files, cost {cost:.4f} USD.\n"
        )
        sections.append(
            render_tables(
                "LLM only",
                ls,
                apply_adjudication(ls, _decisions(root, "llm")),
                (root / BASE / "adjudication" / "llm.json").exists(),
            )  # fmt: skip
        )
    text = "\n".join(sections).rstrip() + "\n"
    (root / BASE / "results.md").write_text(text)
    return text
