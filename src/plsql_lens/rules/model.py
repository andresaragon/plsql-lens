"""Finding model shared by rules and output formats."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from ..parser import FileIR

SEVERITIES = ("info", "low", "medium", "high")


@dataclass(frozen=True, slots=True)
class Location:
    path: str
    line: int
    col: int

    def __str__(self) -> str:
        return f"{self.path}:{self.line}:{self.col}"


@dataclass(frozen=True, slots=True)
class Finding:
    rule_id: str
    severity: str
    location: Location
    message: str
    rationale: str
    fix_hint: str | None = None
    unit: str | None = None  # qualified name of the enclosing unit/subprogram, when known


@dataclass(frozen=True, slots=True)
class Rule:
    id: str
    severity: str
    title: str
    check: Callable[[FileIR], list[Finding]]
