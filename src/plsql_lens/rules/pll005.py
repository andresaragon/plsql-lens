"""PLL005 — row-by-row DML inside a cursor loop."""

from __future__ import annotations

from ..parser import FileIR, Stmt
from ..parser.lexer import IDENT, OP
from .model import Finding, Location, Rule
from .util import iter_bodies

_LOOP_KINDS = ("for_loop", "while_loop", "loop")


def _is_cursor_loop(stmts: tuple[Stmt, ...], hdr_idx: int) -> bool:
    h = stmts[hdr_idx]
    if h.kind == "for_loop":
        return not any(t.kind == OP and t.text == ".." for t in h.tokens)
    inside = h.context + ("loop",)
    for s in stmts[hdr_idx + 1 :]:
        if s.context[: len(inside)] != inside:
            break
        if s.kind == "fetch":
            return True
    return False


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        stmts = body.stmts
        for idx, s in enumerate(stmts):
            if s.kind != "dml":
                continue
            loop_positions = [p for p, c in enumerate(s.context) if c == "loop"]
            flagged = False
            for p in loop_positions:
                for j in range(idx - 1, -1, -1):
                    h = stmts[j]
                    if (
                        h.kind in _LOOP_KINDS
                        and h.context == s.context[:p]
                        and s.blocks[: len(h.blocks)] == h.blocks
                    ):
                        flagged = _is_cursor_loop(stmts, j)
                        break
                if flagged:
                    break
            if flagged:
                verb = next((t.text.upper() for t in s.tokens if t.kind == IDENT), "DML")
                out.append(
                    Finding(
                        "PLL005",
                        "medium",
                        Location(ir.path, s.line, s.col),
                        f"Row-by-row {verb} inside a cursor loop",
                        "One SQL statement per fetched row causes a context switch per row; "
                        "bulk processing is usually orders of magnitude faster.",
                        "Use BULK COLLECT with FORALL, or a single set-based statement.",
                        body.name,
                    )
                )
    return out


RULE = Rule("PLL005", "medium", "Row-by-row DML in cursor loops", check)
