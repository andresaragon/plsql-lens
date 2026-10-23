"""Benchmark data model: manifest of regions with expected findings, and findings to score."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

RULE_IDS = tuple(f"PLL00{i}" for i in range(1, 8))


@dataclass(frozen=True, slots=True)
class Found:
    file: str
    rule: str
    line: int


@dataclass(frozen=True, slots=True)
class Region:
    """A generated snippet: its line span, the rule it labels and where findings are expected."""

    file: str
    rule: str
    kind: str  # "defect" | "negative"
    start: int
    end: int
    expected: tuple[int, ...] = ()
    template: str = ""  # template id, e.g. "d3" / "n2"


@dataclass
class Manifest:
    split: str
    seed: int
    files: dict[str, str]  # path -> "standalone" | "injected"
    regions: list[Region]
    sha256: dict[str, str] = field(default_factory=dict)
    bases: dict[str, str] = field(default_factory=dict)  # injected path -> corpus file

    def to_dict(self) -> dict[str, Any]:
        return {
            "split": self.split,
            "seed": self.seed,
            "files": dict(sorted(self.files.items())),
            "sha256": dict(sorted(self.sha256.items())),
            "bases": dict(sorted(self.bases.items())),
            "regions": [
                {
                    "file": r.file,
                    "rule": r.rule,
                    "kind": r.kind,
                    "start": r.start,
                    "end": r.end,
                    "expected": list(r.expected),
                    "template": r.template,
                }
                for r in self.regions
            ],
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> Manifest:
        regions = [
            Region(r["file"], r["rule"], r["kind"], r["start"], r["end"],
                   tuple(r["expected"]), r.get("template", ""))
            for r in d["regions"]
        ]  # fmt: skip
        return cls(
            d["split"], d["seed"], d["files"], regions, d.get("sha256", {}), d.get("bases", {})
        )

    @classmethod
    def load(cls, path: Path) -> Manifest:
        return cls.from_dict(json.loads(path.read_text()))
