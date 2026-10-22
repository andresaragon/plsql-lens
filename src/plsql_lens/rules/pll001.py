"""PLL001 — WHEN OTHERS handler that swallows the error."""

from __future__ import annotations

from ..parser import FileIR, Stmt
from ..parser.lexer import IDENT
from .model import Finding, Location, Rule
from .util import call_chains, iter_bodies

_ERROR_USE = frozenset(
    ["sqlerrm", "sqlcode", "format_error_stack", "format_error_backtrace", "format_call_stack"]
)
_LOG_PREFIXES = ("log", "audit", "trace")


def _handles(stmts: list[Stmt]) -> bool:
    for s in stmts:
        if s.kind == "raise":
            return True
        for t in s.tokens:
            if t.kind == IDENT and t.text in _ERROR_USE:
                return True
        for chain in call_chains(s.tokens):
            if chain[-1] == "raise_application_error":
                return True
            if any(part.startswith(_LOG_PREFIXES) for part in chain):
                return True
    return False


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        stmts = body.stmts
        for i, h in enumerate(stmts):
            if h.kind != "handler" or [t.text for t in h.tokens] != ["others"]:
                continue
            inside = h.context + ("handler:others",)
            handler_body: list[Stmt] = []
            for s in stmts[i + 1 :]:
                if s.context[: len(inside)] != inside or s.blocks[: len(h.blocks)] != h.blocks:
                    break
                handler_body.append(s)
            if not _handles(handler_body):
                tok = h.tokens[0]
                out.append(
                    Finding(
                        "PLL001",
                        "high",
                        Location(ir.path, tok.line, tok.col),
                        "WHEN OTHERS handler swallows the error: no re-raise, logging or use of "
                        "SQLERRM/SQLCODE",
                        "A catch-all handler that neither re-raises nor records the error hides "
                        "failures from callers and from operators.",
                        "Log the error and re-raise with RAISE, or handle specific exceptions.",
                        body.name,
                    )
                )
    return out


RULE = Rule("PLL001", "high", "WHEN OTHERS without RAISE/logging", check)
