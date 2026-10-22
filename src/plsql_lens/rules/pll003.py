"""PLL003 — COMMIT/ROLLBACK inside a loop."""

from __future__ import annotations

from ..parser import FileIR
from ..parser.lexer import IDENT
from .model import Finding, Location, Rule
from .util import iter_bodies


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        for s in body.stmts:
            if s.kind not in ("commit", "rollback") or "loop" not in s.context:
                continue
            if s.kind == "rollback" and any(t.kind == IDENT and t.text == "to" for t in s.tokens):
                continue  # ROLLBACK TO SAVEPOINT is a partial rollback
            word = s.kind.upper()
            out.append(
                Finding(
                    "PLL003",
                    "medium",
                    Location(ir.path, s.line, s.col),
                    f"{word} inside a loop",
                    "Transaction control per iteration is slow, breaks atomicity of the batch and "
                    "risks ORA-01555.",
                    "Move the transaction control after the loop, or commit every N rows.",
                    body.name,
                )
            )
    return out


RULE = Rule("PLL003", "medium", "COMMIT/ROLLBACK inside a loop", check)
