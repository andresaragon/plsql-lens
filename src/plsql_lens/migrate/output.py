"""Output of migration findings: the table and JSON writers are shared with ``review``; SARIF is
local because ``rules.output.to_sarif`` indexes the review rules (``RULES``)."""

from __future__ import annotations

import json
from collections.abc import Sequence
from pathlib import PurePath
from typing import Any

from .. import __version__
from ..rules.model import Finding
from ..rules.output import to_json, to_table
from .rules import MIGRATION_RULES

_SARIF_SCHEMA = "https://json.schemastore.org/sarif-2.1.0.json"
_LEVEL = {"high": "error", "medium": "warning", "low": "note", "info": "note"}


def to_sarif(findings: Sequence[Finding]) -> str:
    ids = sorted(MIGRATION_RULES)
    rules = [
        {
            "id": rid,
            "name": MIGRATION_RULES[rid].title.replace(" ", "").replace("/", ""),
            "shortDescription": {"text": MIGRATION_RULES[rid].title},
            "defaultConfiguration": {"level": _LEVEL[MIGRATION_RULES[rid].severity]},
        }
        for rid in ids
    ]
    results = [
        {
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
        for f in findings
    ]
    doc: dict[str, Any] = {
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


__all__ = ["to_json", "to_sarif", "to_table"]
