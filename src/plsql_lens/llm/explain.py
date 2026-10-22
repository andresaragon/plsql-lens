"""``--explain``: ask the LLM to explain findings and propose a patch.

The LLM only annotates findings that the deterministic rules already produced. Nothing returned by
the model can add, drop or modify a finding.
"""

from __future__ import annotations

import json
import re
from collections.abc import Mapping, Sequence
from dataclasses import dataclass

from ..rules.model import Finding
from .providers import LLMError, LLMProvider, LLMResponse, UsageLog

CONTEXT_LINES = 8

_INSTRUCTIONS = (
    "You are reviewing Oracle PL/SQL. A deterministic static-analysis rule produced the "
    "finding below. Explain briefly why it is a problem in THIS code and propose a minimal "
    "fix as replacement code. Do not report other issues and do not dispute whether the "
    "finding exists. Reply with only a JSON object: "
    '{"explanation": "<2-4 sentences>", "patch": "<replacement code or null>"}.'
)


@dataclass(frozen=True, slots=True)
class Explanation:
    finding: Finding
    explanation: str | None
    patch: str | None
    response: LLMResponse | None = None
    error: str | None = None


def build_prompt(f: Finding, source: str) -> str:
    lines = source.splitlines()
    lo = max(1, f.location.line - CONTEXT_LINES)
    hi = min(len(lines), f.location.line + CONTEXT_LINES)
    code = "\n".join(f"{n:5d} {lines[n - 1]}" for n in range(lo, hi + 1))
    return (
        f"{_INSTRUCTIONS}\n\n"
        f"Rule: {f.rule_id} ({f.severity}) - {f.message}\n"
        f"Rationale: {f.rationale}\n"
        f"Location: {f.location}\n\n"
        f"Code (line numbers on the left):\n{code}\n"
    )


_FENCE = re.compile(r"```(?:json)?\s*(\{.*?\})\s*```", re.DOTALL)


def parse_explanation(text: str) -> tuple[str, str | None] | None:
    """Extract ``(explanation, patch)`` from the model's reply, or None if unusable."""
    candidates = [text.strip()]
    if m := _FENCE.search(text):
        candidates.insert(0, m.group(1))
    if (a := text.find("{")) >= 0 and (b := text.rfind("}")) > a:
        candidates.append(text[a : b + 1])
    for c in candidates:
        try:
            data = json.loads(c)
        except ValueError:
            continue
        if (
            isinstance(data, dict)
            and isinstance(data.get("explanation"), str)
            and data["explanation"]
        ):
            patch = data.get("patch")
            return data["explanation"], patch if isinstance(patch, str) else None
    return None


def explain_findings(
    findings: Sequence[Finding],
    sources: Mapping[str, str],
    provider: LLMProvider,
    log: UsageLog,
    limit: int | None = None,
) -> list[Explanation]:
    """Return one Explanation per finding (same order); at most ``limit`` get an LLM call."""
    out: list[Explanation] = []
    for i, f in enumerate(findings):
        if limit is not None and i >= limit:
            out.append(Explanation(f, None, None, error="not explained (limit reached)"))
            continue
        try:
            resp = provider.complete(build_prompt(f, sources.get(f.location.path, "")))
        except LLMError as e:
            out.append(Explanation(f, None, None, error=str(e)))
            continue
        log.add(resp)
        parsed = parse_explanation(resp.text)
        if parsed is None:
            out.append(Explanation(f, None, None, resp, "unusable LLM reply"))
        else:
            out.append(Explanation(f, parsed[0], parsed[1], resp))
    return out
