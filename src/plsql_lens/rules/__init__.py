"""Review rules: deterministic functions from IR to findings."""

from __future__ import annotations

from collections.abc import Iterable

from ..parser import FileIR
from . import pll001, pll002, pll003, pll004, pll005, pll006, pll007
from .model import SEVERITIES, Finding, Location, Rule

RULES: dict[str, Rule] = {
    r.id: r
    for r in (
        pll001.RULE,
        pll002.RULE,
        pll003.RULE,
        pll004.RULE,
        pll005.RULE,
        pll006.RULE,
        pll007.RULE,
    )
}


def review(ir: FileIR, rules: Iterable[str] | None = None) -> list[Finding]:
    """Run the selected rules (default: all) and return findings sorted by location."""
    selected = [RULES[r] for r in (sorted(RULES) if rules is None else rules)]
    findings = [f for rule in selected for f in rule.check(ir)]
    findings.sort(key=lambda f: (f.location.line, f.location.col, f.rule_id))
    return findings


__all__ = ["RULES", "SEVERITIES", "Finding", "Location", "Rule", "review"]
