"""Intermediate representation produced by the structural parser (frozen dataclasses)."""

from __future__ import annotations

from dataclasses import dataclass, field

UNIT_KINDS = ("package", "package_body", "procedure", "function", "trigger", "type", "type_body")


@dataclass(frozen=True, slots=True)
class Param:
    name: str
    mode: str  # "in" | "out" | "in out"
    type: str
    has_default: bool = False


@dataclass(frozen=True, slots=True)
class Call:
    """A candidate call site: a dotted identifier chain followed by ``(`` or ``;``."""

    chain: tuple[str, ...]
    line: int
    col: int
    followed_by: str  # "(" or ";" or "other"


@dataclass(frozen=True, slots=True)
class Subprogram:
    kind: str  # "procedure" | "function"
    name: str
    params: tuple[Param, ...]
    return_type: str | None
    line: int
    has_body: bool
    calls: tuple[Call, ...] = ()
    nested: tuple[Subprogram, ...] = ()
    locals: frozenset[str] = frozenset()  # params, local declarations and nested subprogram names


@dataclass(frozen=True, slots=True)
class Unit:
    """A top-level object: package/type spec or body, standalone subprogram, or trigger."""

    kind: str  # one of UNIT_KINDS
    name: str  # lowercase, schema prefix removed
    line: int
    params: tuple[Param, ...] = ()
    return_type: str | None = None
    subprograms: tuple[Subprogram, ...] = ()
    calls: tuple[Call, ...] = ()  # standalone body / trigger body / package initialization block
    locals: frozenset[str] = frozenset()


@dataclass(frozen=True, slots=True)
class ParseIssue:
    line: int
    message: str


@dataclass(frozen=True, slots=True)
class FileIR:
    path: str
    lines: int
    units: tuple[Unit, ...] = ()
    issues: tuple[ParseIssue, ...] = field(default=())

    @property
    def ok(self) -> bool:
        """True when the file was fully consumed without structural errors."""
        return not self.issues
