"""Output formats for findings: plain-text table, JSON and SARIF 2.1.0."""

from __future__ import annotations

import json
from collections.abc import Sequence
from pathlib import PurePath
from typing import Any

from .. import __version__
from . import RULES
from .model import Finding

_SARIF_SCHEMA = "https://json.schemastore.org/sarif-2.1.0.json"
_LEVEL = {"high": "error", "medium": "warning", "low": "note", "info": "note"}


def to_table(findings: Sequence[Finding]) -> str:
    if not findings:
        return "No findings.\n"
    rows = [(f.severity.upper(), f.rule_id, str(f.location), f.message) for f in findings]
    head = ("SEVERITY", "RULE", "LOCATION", "MESSAGE")
    widths = [max(len(r[i]) for r in [head, *rows]) for i in range(3)]
    lines = [
        "  ".join(h.ljust(w) for h, w in zip(head[:3], widths, strict=True)) + "  " + head[3],
        "  ".join("-" * w for w in widths) + "  -------",
    ]
    for r in rows:
        lines.append(
            "  ".join(c.ljust(w) for c, w in zip(r[:3], widths, strict=True)) + "  " + r[3]
        )
    return "\n".join(lines) + "\n"


Notes = Sequence["tuple[str | None, str | None]"]  # per finding: (explanation, patch)


def table_notes(findings: Sequence[Finding], notes: Notes) -> str:
    """Append-only section listing LLM explanations under a table."""
    parts = []
    for f, (expl, patch) in zip(findings, notes, strict=False):
        if expl:
            parts.append(f"\n{f.rule_id} {f.location}\n  {expl}")
            if patch:
                parts.append(
                    "  Suggested patch:\n" + "\n".join(f"    {ln}" for ln in patch.splitlines())
                )
    return "\n".join(parts) + ("\n" if parts else "")


def _finding_dict(f: Finding) -> dict[str, Any]:
    return {
        "rule_id": f.rule_id,
        "severity": f.severity,
        "file": f.location.path,
        "line": f.location.line,
        "col": f.location.col,
        "message": f.message,
        "rationale": f.rationale,
        "fix_hint": f.fix_hint,
        "unit": f.unit,
    }


def to_json(
    findings: Sequence[Finding],
    notes: Notes | None = None,
    usage: dict[str, object] | None = None,
) -> str:
    items = [_finding_dict(f) for f in findings]
    for item, (expl, patch) in zip(items, notes or [], strict=False):
        item["explanation"], item["patch"] = expl, patch
    doc: dict[str, Any] = {"version": __version__, "findings": items}
    if usage is not None:
        doc["llm_usage"] = usage
    return json.dumps(doc, indent=2) + "\n"


def to_sarif(findings: Sequence[Finding], notes: Notes | None = None) -> str:
    ids = sorted(RULES)
    rules = [
        {
            "id": rid,
            "name": RULES[rid].title.replace(" ", ""),
            "shortDescription": {"text": RULES[rid].title},
            "defaultConfiguration": {"level": _LEVEL[RULES[rid].severity]},
        }
        for rid in ids
    ]
    results = []
    for f in findings:
        res: dict[str, Any] = {
            "ruleId": f.rule_id,
            "ruleIndex": ids.index(f.rule_id),
            "level": _LEVEL[f.severity],
            "message": {"text": f.message + (f" Fix: {f.fix_hint}" if f.fix_hint else "")},
            "locations": [
                {
                    "physicalLocation": {
                        "artifactLocation": {"uri": PurePath(f.location.path).as_posix()},
                        "region": {"startLine": f.location.line, "startColumn": f.location.col},
                    }
                }
            ],
        }
        results.append(res)
    for res, (expl, patch) in zip(results, notes or [], strict=False):
        if expl:
            res["properties"] = {"explanation": expl, "suggestedPatch": patch}
    doc = {
        "$schema": _SARIF_SCHEMA,
        "version": "2.1.0",
        "runs": [
            {
                "tool": {"driver": {"name": "plsql-lens", "version": __version__, "rules": rules}},
                "results": results,
            }
        ],
    }
    return json.dumps(doc, indent=2) + "\n"
