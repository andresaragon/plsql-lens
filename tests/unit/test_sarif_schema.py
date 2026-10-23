"""Validate SARIF output against the official SARIF 2.1.0 JSON Schema (vendored, MIT)."""

from __future__ import annotations

import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

from plsql_lens import parse_file
from plsql_lens.rules import RULES, review
from plsql_lens.rules.output import to_sarif

ROOT = Path(__file__).resolve().parents[2]
SCHEMA = json.loads((ROOT / "tests" / "vendor" / "sarif-2.1.0.json").read_text())
FIXTURES = ROOT / "tests" / "fixtures" / "rules"


def _errors(doc: object) -> list[str]:
    validator = Draft202012Validator(SCHEMA)
    return [f"{'/'.join(map(str, e.path))}: {e.message}" for e in validator.iter_errors(doc)]


def test_empty_run_validates() -> None:
    assert _errors(json.loads(to_sarif([]))) == []


@pytest.mark.parametrize("rule", sorted(RULES))
def test_every_rule_output_validates(rule: str) -> None:
    findings = review(parse_file(FIXTURES / rule / "pos_1.pkb"), rules=[rule])
    assert findings
    notes = [("because", "patch")] * len(findings)
    assert _errors(json.loads(to_sarif(findings, notes))) == []


def test_schema_rejects_a_broken_document() -> None:
    doc = json.loads(to_sarif([]))
    doc["runs"][0]["results"] = [{"ruleId": "X", "level": "catastrophic", "message": {}}]
    assert _errors(doc)
