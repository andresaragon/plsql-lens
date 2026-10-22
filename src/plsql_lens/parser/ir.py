"""Intermediate representation produced by the structural parser (frozen dataclasses)."""

from __future__ import annotations

from dataclasses import dataclass, field

from .lexer import Token

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
class Stmt:
    """One statement (or block header) with the stack of enclosing constructs.

    ``kind``: assign, call, select, select_into, select_bulk, dml, execute_immediate, open,
    open_for, forall, commit, rollback, savepoint, raise, return, exit, continue, null, goto, close,
    fetch, pipe, other, or a block header: if, elsif, case, when, handler, loop, for_loop,
    while_loop.
    ``context``: enclosing constructs, outermost first: ``begin``, ``loop``, ``if``, ``case`` or
    ``handler:<exception names>``.
    """

    kind: str
    tokens: tuple[Token, ...]
    context: tuple[str, ...]
    line: int
    col: int
    blocks: tuple[int, ...] = (0,)  # ids of enclosing BEGIN blocks, root first (root = 0)


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
    body: tuple[Stmt, ...] = ()
    end_line: int = 0
    local_types: tuple[tuple[str, str], ...] = ()  # (name, type) for params and simple locals


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
    body: tuple[Stmt, ...] = ()  # standalone / trigger body, package initialization block
    end_line: int = 0
    local_types: tuple[tuple[str, str], ...] = ()


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
    # (target line, rule ids) from ``-- plsql-lens: disable=…`` comments
    suppressions: tuple[tuple[int, frozenset[str]], ...] = ()

    @property
    def ok(self) -> bool:
        """True when the file was fully consumed without structural errors."""
        return not self.issues
