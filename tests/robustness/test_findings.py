"""Minimized reproductions of the claim "the parser never raises" failing (issue #16).

Each finding is a small JSON recipe under ``tests/robustness/findings/`` (text parts repeated N
times) so the input stays reviewable. The parser is frozen, so these are ``xfail(strict=True)``:
when someone fixes one, the strict xfail turns the run red and the entry must be removed.
"""

from __future__ import annotations

import functools
from pathlib import Path

import pytest
from mutate import (
    MUTATIONS,
    SEED,
    Finding,
    Outcome,
    have_time_limit,
    load_findings,
    run_guarded,
)

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "docs" / "reports" / "robustness.md"
FINDINGS = load_findings()

pytestmark = [
    pytest.mark.robustness,
    pytest.mark.skipif(not have_time_limit(), reason="needs signal.setitimer (Linux/macOS)"),
]


@functools.cache
def _outcome(name: str) -> Outcome:
    finding = next(f for f in FINDINGS if f.name == name)
    return run_guarded(finding.data)


def test_findings_are_recorded_with_a_reason_and_a_signature() -> None:
    assert FINDINGS, "no findings recorded; delete this test if the parser is ever fully robust"
    assert len({f.name for f in FINDINGS}) == len(FINDINGS)
    for f in FINDINGS:
        assert f.reason.strip() and f.signature and f.data


@pytest.mark.parametrize("finding", FINDINGS, ids=lambda f: f.name)
def test_finding_fails_with_the_recorded_signature(finding: Finding) -> None:
    assert _outcome(finding.name).signature == finding.signature


@pytest.mark.parametrize(
    "finding",
    [pytest.param(f, marks=pytest.mark.xfail(strict=True, reason=f.reason)) for f in FINDINGS],
    ids=lambda f: f.name,
)
def test_parser_claim_holds_on_the_minimized_input(finding: Finding) -> None:
    out = _outcome(finding.name)
    assert out.ok, out.signature


def test_report_mentions_every_finding_and_the_run_parameters() -> None:
    text = REPORT.read_text()
    for f in FINDINGS:
        assert f"`{f.name}`" in text, f"{f.name} is not described in the report"
    assert str(SEED) in text
    assert str(MUTATIONS) in text
