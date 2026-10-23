"""PLL007 — magic literals repeated in executable code."""

from __future__ import annotations

from collections import defaultdict

from ..parser import FileIR
from ..parser.lexer import NUMBER, STRING, Token
from .model import Finding, Location, Rule
from .util import iter_bodies

MIN_REPEATS = 3


def _string_value(text: str) -> str:
    """Value of a string literal: ``''`` is one quote, ``q'[...]'`` has no delimiters."""
    body = text[text.index("'") + 1 : -1]
    if text[:1] in "qQ" or text[:2].lower() == "nq":
        return body[1:-1]
    return body.replace("''", "'")


def _is_candidate(t: Token) -> bool:
    if t.kind == NUMBER:
        try:
            return float(t.text) not in (0.0, 1.0)
        except ValueError:
            return False
    if t.kind == STRING:
        inner = _string_value(t.text)
        return not (inner == "" or (len(inner) == 1 and not inner.isalnum()))
    return False


def check(ir: FileIR) -> list[Finding]:
    groups: dict[tuple[str, str], list[tuple[Token, str]]] = defaultdict(list)
    for body in iter_bodies(ir):
        for s in body.stmts:
            for t in s.tokens:
                if _is_candidate(t):
                    groups[(body.unit, t.text)].append((t, body.name))
    out: list[Finding] = []
    for (_unit, lit), occ in groups.items():
        if len(occ) < MIN_REPEATS:
            continue
        for t, owner in occ:
            out.append(
                Finding(
                    "PLL007",
                    "info",
                    Location(ir.path, t.line, t.col),
                    f"Magic literal {lit} is repeated {len(occ)} times in this unit",
                    "Repeated literals hide intent and must be changed in several places.",
                    "Declare a named constant and reference it.",
                    owner,
                )
            )
    return out


RULE = Rule("PLL007", "info", "Magic literals", check)
