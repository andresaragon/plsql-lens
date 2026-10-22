"""PLL002 — dynamic SQL built by string concatenation."""

from __future__ import annotations

from ..parser import FileIR, Stmt
from ..parser.lexer import IDENT, OP, STRING, Token
from .model import Finding, Location, Rule
from .util import iter_bodies

_END_WORDS = frozenset(["into", "using", "returning", "bulk"])


def _segments(tokens: list[Token]) -> list[list[Token]]:
    """Split on top-level ``||``."""
    segs: list[list[Token]] = [[]]
    depth = 0
    for t in tokens:
        if t.kind == OP and t.text == "(":
            depth += 1
        elif t.kind == OP and t.text == ")":
            depth -= 1
        if t.kind == OP and t.text == "||" and depth == 0:
            segs.append([])
        else:
            segs[-1].append(t)
    return segs


def _safe(seg: list[Token]) -> bool:
    if len(seg) == 1 and seg[0].kind in (STRING, "number"):
        return True
    names = [t.text for t in seg if t.kind == IDENT]
    if names and names[0] in ("dbms_assert", "sys") and "dbms_assert" in names[:2]:
        return True
    return bool(names) and names[0] == "chr" and all(t.kind != IDENT for t in seg[1:])


def _concatenates_unsafely(tokens: list[Token]) -> bool:
    segs = _segments(tokens)
    return len(segs) > 1 and any(not _safe(s) for s in segs)


def _sql_tokens(s: Stmt) -> list[Token] | None:
    toks = list(s.tokens)
    if s.kind == "execute_immediate":
        toks = toks[2:]
    else:  # open_for
        idx = next((i for i, t in enumerate(toks) if t.kind == IDENT and t.text == "for"), None)
        if idx is None:
            return None
        toks = toks[idx + 1 :]
        if toks and toks[0].kind == IDENT and toks[0].text in ("select", "with"):
            return None  # static query, not dynamic SQL
    out: list[Token] = []
    depth = 0
    for t in toks:
        if t.kind == OP and t.text == "(":
            depth += 1
        elif t.kind == OP and t.text == ")":
            depth -= 1
        if depth == 0 and t.kind == IDENT and t.text in _END_WORDS:
            break
        out.append(t)
    return out


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        for idx, s in enumerate(body.stmts):
            if s.kind not in ("execute_immediate", "open_for"):
                continue
            sql = _sql_tokens(s)
            if not sql:
                continue
            bad = _concatenates_unsafely(sql)
            if not bad and len(sql) == 1 and sql[0].kind == IDENT:
                var = sql[0].text
                for prev in body.stmts[:idx]:
                    if prev.kind == "assign" and prev.tokens[0].text == var:
                        rhs = [t for t in prev.tokens]
                        pos = next(
                            (i for i, t in enumerate(rhs) if t.kind == OP and t.text == ":="), None
                        )
                        if pos is not None and _concatenates_unsafely(rhs[pos + 1 :]):
                            bad = True
                            break
            if bad:
                out.append(
                    Finding(
                        "PLL002",
                        "high",
                        Location(ir.path, s.line, s.col),
                        "Dynamic SQL is built by string concatenation instead of bind variables",
                        "Concatenating values into SQL text enables SQL injection and defeats "
                        "cursor sharing.",
                        "Use bind variables (USING / OPEN … FOR … USING); wrap identifiers with "
                        "DBMS_ASSERT.",
                        body.name,
                    )
                )
    return out


RULE = Rule("PLL002", "high", "Dynamic SQL by concatenation", check)
