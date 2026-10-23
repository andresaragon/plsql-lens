"""Scoring: TP / FP / FN against a manifest (definition in docs/benchmarks/README.md)."""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass, field
from typing import Any

from .model import RULE_IDS, Found, Manifest, Region
from .stats import prf


@dataclass
class Counts:
    tp: int = 0
    fp: int = 0
    fn: int = 0

    def metrics(self) -> dict[str, Any]:
        return prf(self.tp, self.fp, self.fn)


@dataclass
class Score:
    per_rule: dict[str, Counts] = field(default_factory=lambda: {r: Counts() for r in RULE_IDS})
    background: int = 0  # findings in injected files outside any generated region (not scored)
    cross: int = 0  # findings of a rule other than the one a region labels (not scored)

    @property
    def total(self) -> Counts:
        t = Counts()
        for c in self.per_rule.values():
            t.tp, t.fp, t.fn = t.tp + c.tp, t.fp + c.fp, t.fn + c.fn
        return t

    def to_dict(self) -> dict[str, Any]:
        return {
            "per_rule": {r: c.metrics() for r, c in self.per_rule.items()},
            "total": self.total.metrics(),
            "background_findings": self.background,
            "cross_rule_findings": self.cross,
        }


def score(manifest: Manifest, findings: Iterable[Found]) -> Score:
    """Score findings. A finding is a TP when its rule and line match an expected line of a defect
    region; an FP when it is a same-rule finding anywhere else in a generated region, or anywhere in a
    standalone file outside regions; an FN is an expected line nobody reported. Findings of other
    rules inside a region, and findings in injected files outside regions, are not scored."""
    res = Score()
    by_file: dict[str, list[Region]] = {}
    for r in manifest.regions:
        by_file.setdefault(r.file, []).append(r)
    matched: set[tuple[str, str, int]] = set()
    for f in sorted({(x.file, x.rule, x.line) for x in findings}):
        file, rule, line = f
        if rule not in res.per_rule:
            continue
        region = next((r for r in by_file.get(file, ()) if r.start <= line <= r.end), None)
        if region is None:
            if manifest.files.get(file) == "standalone":
                res.per_rule[rule].fp += 1
            else:
                res.background += 1
        elif region.rule != rule:
            res.cross += 1
        elif region.kind == "defect" and line in region.expected:
            matched.add(f)
            res.per_rule[rule].tp += 1
        else:
            res.per_rule[rule].fp += 1
    for r in manifest.regions:
        if r.kind == "defect":
            res.per_rule[r.rule].fn += sum(
                1 for line in r.expected if (r.file, r.rule, line) not in matched
            )
    return res
