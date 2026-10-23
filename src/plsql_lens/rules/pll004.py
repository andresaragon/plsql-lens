"""PLL004 — SELECT INTO without NO_DATA_FOUND / TOO_MANY_ROWS handling."""

from __future__ import annotations

from ..parser import FileIR, Stmt
from ..parser.lexer import IDENT, OP, Token
from .model import Finding, Location, Rule
from .util import iter_bodies

_HANDLED = frozenset(["no_data_found", "too_many_rows", "others"])
_AGG = frozenset(["count", "sum", "avg", "min", "max", "listagg"])


def _always_one_row(s: Stmt) -> bool:
    """Queries that return exactly one row: ``FROM dual``, or an aggregate in the select list
    (at any expression depth, not in a scalar subquery, not analytic) with no GROUP BY/HAVING."""
    words = [t.text for t in s.tokens if t.kind == IDENT]
    toks = s.tokens
    if any(a == "from" and b == "dual" for a, b in zip(words, words[1:], strict=False)):
        return True
    if "having" in words or any(
        a == "group" and b == "by" for a, b in zip(words, words[1:], strict=False)
    ):
        return False
    into = next((i for i, t in enumerate(toks) if t.kind == IDENT and t.text == "into"), 0)
    depth = 0
    subquery_depths: list[int] = []
    for i, t in enumerate(toks[:into]):
        if t.kind == OP and t.text == "(":
            depth += 1
            if i + 1 < len(toks) and toks[i + 1].text == "select":
                subquery_depths.append(depth)
        elif t.kind == OP and t.text == ")":
            if subquery_depths and subquery_depths[-1] == depth:
                subquery_depths.pop()
            depth -= 1
        elif (
            t.kind == IDENT
            and t.text in _AGG
            and not subquery_depths
            and i + 1 < len(toks)
            and toks[i + 1].text == "("
            and not _is_analytic(toks, i + 1)
        ):
            return True
    return False


def _is_analytic(toks: tuple[Token, ...], open_idx: int) -> bool:
    """True when the call opened at ``open_idx`` is followed by ``OVER`` (per-row, not one row)."""
    depth = 0
    for j in range(open_idx, len(toks)):
        if toks[j].kind == OP and toks[j].text == "(":
            depth += 1
        elif toks[j].kind == OP and toks[j].text == ")":
            depth -= 1
            if depth == 0:
                nxt = toks[j + 1] if j + 1 < len(toks) else None
                if (
                    nxt is not None and nxt.text == "within"
                ):  # LISTAGG(...) WITHIN GROUP (...) [OVER]
                    k = j + 2
                    while k < len(toks) and toks[k].text != ")":
                        k += 1
                    nxt = toks[k + 1] if k + 1 < len(toks) else None
                return nxt is not None and nxt.text == "over"
    return False


def _in_handler_section(s: Stmt, level: int) -> bool:
    """True if ``s`` sits in the EXCEPTION section of its ``level``-th enclosing block."""
    begins = [i for i, c in enumerate(s.context) if c == "begin"]
    start = -1 if level == 0 else begins[level - 1]
    end = begins[level] if level < len(begins) else len(s.context)
    return any(c.startswith("handler:") for c in s.context[start + 1 : end])


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        stmts = body.stmts
        for idx, s in enumerate(stmts):
            if s.kind != "select_into" or _always_one_row(s):
                continue
            handled = False
            for level, block in enumerate(s.blocks):
                if _in_handler_section(s, level):
                    continue
                for h in stmts[idx + 1 :]:
                    if (
                        h.kind == "handler"
                        and h.blocks[-1] == block
                        and any(t.text in _HANDLED for t in h.tokens if t.kind == IDENT)
                    ):
                        handled = True
                        break
                if handled:
                    break
            if not handled:
                out.append(
                    Finding(
                        "PLL004",
                        "medium",
                        Location(ir.path, s.line, s.col),
                        "SELECT INTO without NO_DATA_FOUND/TOO_MANY_ROWS handling in scope",
                        "A single-row SELECT INTO raises when zero or several rows match; the "
                        "error escapes to the caller unhandled.",
                        "Add a handler for NO_DATA_FOUND and TOO_MANY_ROWS in the enclosing "
                        "block, or use an explicit cursor.",
                        body.name,
                    )
                )
    return out


RULE = Rule("PLL004", "medium", "SELECT INTO without exception handling", check)
