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


def to_json(findings: Sequence[Finding]) -> str:
    doc = {"version": __version__, "findings": [_finding_dict(f) for f in findings]}
    return json.dumps(doc, indent=2) + "\n"


def to_sarif(findings: Sequence[Finding]) -> str:
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
