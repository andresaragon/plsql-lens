"""Helpers shared by rules: walking bodies and querying the statement layer."""

from __future__ import annotations

from collections.abc import Iterator
from dataclasses import dataclass

from ..parser import FileIR, Stmt, Subprogram, Unit
from ..parser.lexer import IDENT, OP, Token


@dataclass(frozen=True, slots=True)
class Body:
    """A statement body together with the name that owns it and its declared local types."""

    name: str  # qualified, e.g. "pkg.proc"
    stmts: tuple[Stmt, ...]
    local_types: dict[str, str]
    unit: str  # enclosing top-level unit name
    header_line: int
    end_line: int


def iter_bodies(ir: FileIR) -> Iterator[Body]:
    """Every non-empty body in the file: package init blocks, subprograms (nested included)."""

    def walk_sub(sp: Subprogram, prefix: str, unit: str) -> Iterator[Body]:
        qn = f"{prefix}.{sp.name}"
        if sp.body:
            yield Body(qn, sp.body, dict(sp.local_types), unit, sp.line, sp.end_line)
        for n in sp.nested:
            yield from walk_sub(n, qn, unit)

    def walk_unit(u: Unit) -> Iterator[Body]:
        if u.body:
            yield Body(u.name, u.body, dict(u.local_types), u.name, u.line, u.end_line)
        for sp in u.subprograms:
            yield from walk_sub(sp, u.name, u.name)

    for u in ir.units:
        yield from walk_unit(u)


def text(tokens: tuple[Token, ...] | list[Token]) -> str:
    return " ".join(t.text for t in tokens)


def call_chains(tokens: tuple[Token, ...] | list[Token]) -> Iterator[tuple[str, ...]]:
    """Dotted identifier chains followed by ``(`` or ``;`` or end of tokens (candidate calls)."""
    i, n = 0, len(tokens)
    while i < n:
        t = tokens[i]
        if t.kind != IDENT or (i and tokens[i - 1].kind == OP and tokens[i - 1].text == "."):
            i += 1
            continue
        chain = [t.text]
        j = i + 1
        while (
            j + 1 < n
            and tokens[j].kind == OP
            and tokens[j].text == "."
            and tokens[j + 1].kind == IDENT
        ):
            chain.append(tokens[j + 1].text)
            j += 2
        if j >= n or (tokens[j].kind == OP and tokens[j].text in ("(", ";")):
            yield tuple(chain)
        i = j
