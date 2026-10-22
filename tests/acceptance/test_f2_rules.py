"""Phase F2 acceptance tests for the review rules (SPEC section 3, F2).

Fixtures in tests/fixtures/rules/<RULE>/{pos,neg}_N.pkb were written from docs/rules.md, not from
the implementation. A trailing ``-- expect: PLLnnn`` marks the exact line of an expected finding.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

from plsql_lens import parse_file
from plsql_lens.rules import RULES, review

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "tests" / "fixtures" / "rules"
RULE_IDS = [f"PLL00{i}" for i in range(1, 8)]
EXPECT = re.compile(r"--\s*expect:\s*(PLL\d{3})")


def expected_lines(path: Path, rule: str) -> set[int]:
    return {
        n
        for n, line in enumerate(path.read_text().splitlines(), 1)
        if (m := EXPECT.search(line)) and m.group(1) == rule
    }


def found_lines(path: Path, rule: str) -> set[int]:
    return {f.location.line for f in review(parse_file(path)) if f.rule_id == rule}


def test_all_seven_rules_registered() -> None:
    assert sorted(RULES) == RULE_IDS


@pytest.mark.parametrize("rule", RULE_IDS)
def test_rule_has_three_positive_and_three_negative_fixtures(rule: str) -> None:
    assert len(list((FIXTURES / rule).glob("pos_*.pkb"))) >= 3
    assert len(list((FIXTURES / rule).glob("neg_*.pkb"))) >= 3
    for pos in (FIXTURES / rule).glob("pos_*.pkb"):
        assert expected_lines(pos, rule), f"{pos.name} has no expect marker"
    for neg in (FIXTURES / rule).glob("neg_*.pkb"):
        assert not expected_lines(neg, rule), f"{neg.name} must not expect {rule}"


CASES = [
    pytest.param(rule, path, id=f"{rule}/{path.name}")
    for rule in RULE_IDS
    for path in sorted((FIXTURES / rule).glob("*.pkb"))
]


@pytest.mark.parametrize(("rule", "path"), CASES)
def test_fixture_findings_match_markers(rule: str, path: Path) -> None:
    assert found_lines(path, rule) == expected_lines(path, rule)


CORPUS_CASES = json.loads((Path(__file__).parent / "corpus_cases.json").read_text())["cases"]


@pytest.mark.parametrize(
    "case", CORPUS_CASES, ids=lambda c: f"{c['rule']}:{Path(c['file']).name}:{c['line']}"
)
def test_corpus_cases(case: dict[str, object]) -> None:
    lines = found_lines(ROOT / str(case["file"]), str(case["rule"]))
    assert (case["line"] in lines) is case["expect"], case["note"]


def test_findings_have_required_fields() -> None:
    pos = FIXTURES / "PLL001" / "pos_1.pkb"
    findings = [f for f in review(parse_file(pos)) if f.rule_id == "PLL001"]
    assert findings
    f = findings[0]
    assert f.severity == "high"
    assert f.location.path.endswith("pos_1.pkb") and f.location.line > 0 and f.location.col > 0
    assert str(f.location).endswith(f":{f.location.line}:{f.location.col}")
    assert f.message and f.rationale
