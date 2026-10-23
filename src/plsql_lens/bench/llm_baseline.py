"""LLM-only baseline: the model lists findings for the seven rules without the rule engine."""

from __future__ import annotations

import json
import random
import re
from pathlib import Path
from typing import Any

from ..llm import LLMError, LLMProvider
from .model import Found, Manifest

_FENCE = re.compile(r"```(?:json)?\s*(.*?)```", re.DOTALL)

INSTRUCTIONS = """\
You are a PL/SQL code reviewer. Report findings for exactly these seven rules, using the contract
below (it defines each rule and the line where its finding is reported):

{rules}

Reply with ONLY a JSON array of objects {{"rule": "PLL001", "line": 42}}, one per finding, sorted by
line; use [] if there are none. Line numbers are the ones printed in the file listing. Do not explain.

File {name}:
{code}
"""


def rules_contract(root: Path) -> str:
    text = (root / "docs" / "rules.md").read_text()
    start = text.index("| Rule |")
    end = text.index("## Suppression")
    return text[start:end].strip()


def select_sample(manifest: Manifest, n: int, seed: int) -> list[str]:
    """Seeded sample of ``n`` files, half standalone and half injected (as far as available)."""
    rng = random.Random(seed)
    groups = {
        k: sorted(p for p, kind in manifest.files.items() if kind == k)
        for k in ("standalone", "injected")
    }
    take = {k: min(len(v), n // 2) for k, v in groups.items()}
    rest = n - sum(take.values())
    for k in groups:
        extra = min(rest, len(groups[k]) - take[k])
        take[k] += extra
        rest -= extra
    return sorted(f for k, v in groups.items() for f in rng.sample(v, take[k]))


def build_prompt(root: Path, name: str, text: str) -> str:
    code = "\n".join(f"{i:5d} {ln}" for i, ln in enumerate(text.splitlines(), 1))
    return INSTRUCTIONS.format(rules=rules_contract(root), name=name, code=code)


def parse_findings(text: str, file: str) -> list[Found]:
    m = _FENCE.search(text)
    raw = m.group(1) if m else text
    a, b = raw.find("["), raw.rfind("]")
    try:
        data = json.loads(raw[a : b + 1]) if a >= 0 and b > a else []
    except ValueError:
        return []
    out = []
    for e in data if isinstance(data, list) else []:
        if (
            isinstance(e, dict)
            and isinstance(e.get("rule"), str)
            and isinstance(e.get("line"), int)
        ):
            out.append(Found(file, e["rule"].upper(), e["line"]))
    return out


def run_baseline(
    root: Path, data_dir: Path, files: list[str], provider: LLMProvider, model: str
) -> dict[str, Any]:
    """Call the provider once per file; return the recordings (committed so `make bench` can replay)."""
    rec: dict[str, Any] = {"model": model, "responses": {}}
    for f in files:
        prompt = build_prompt(root, f, (data_dir / f).read_text())
        try:
            r = provider.complete(prompt)
            rec["responses"][f] = {"text": r.text, "input_tokens": r.input_tokens,
                                   "output_tokens": r.output_tokens, "cost_usd": r.cost_usd}  # fmt: skip
        except LLMError as e:
            rec["responses"][f] = {
                "error": str(e),
                "input_tokens": 0,
                "output_tokens": 0,
                "cost_usd": 0.0,
            }
    return rec


def findings_from_recording(rec: dict[str, Any]) -> list[Found]:
    out: list[Found] = []
    for f, r in sorted(rec["responses"].items()):
        out.extend(parse_findings(r.get("text", ""), f))
    return out
