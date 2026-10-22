"""PLL006 — implicit conversions (limited, type-aware only for simple operands)."""

from __future__ import annotations

from ..parser import FileIR
from ..parser.lexer import IDENT, NUMBER, OP, STRING, Token
from .model import Finding, Location, Rule
from .util import iter_bodies

_SQL_KINDS = frozenset(
    ["dml", "select", "select_into", "select_bulk", "execute_immediate", "open_for", "forall"]
)
_COMPARE = frozenset(["=", "<>", "!=", "<", ">", "<=", ">=", "^=", "~="])
_TEXT = ("varchar", "char", "nvarchar", "nchar", "clob", "string", "long")
_NUMBER = (
    "number", "integer", "int", "pls_integer", "binary_integer", "float", "decimal", "numeric",
    "simple_integer", "natural", "positive", "smallint", "real", "double", "binary_float",
    "binary_double",
)  # fmt: skip
_DATE = ("date", "timestamp")
_TO_DATE = frozenset(["to_date", "to_timestamp", "to_timestamp_tz"])


def _family_of_type(type_text: str) -> str | None:
    t = type_text.lower()
    if "%" in t:
        return None  # anchored types are not resolved
    for fam, prefixes in (("text", _TEXT), ("number", _NUMBER), ("date", _DATE)):
        if t.startswith(prefixes):
            return fam
    return None


def _operand_family(tok: Token, types: dict[str, str]) -> str | None:
    if tok.kind == STRING:
        return "text"
    if tok.kind == NUMBER:
        return "number"
    if tok.kind == IDENT and tok.text in types:
        return _family_of_type(types[tok.text])
    return None


def _single_argument(tokens: tuple[Token, ...], open_idx: int) -> bool:
    depth = 0
    for t in tokens[open_idx:]:
        if t.kind == OP and t.text == "(":
            depth += 1
        elif t.kind == OP and t.text == ")":
            depth -= 1
            if depth == 0:
                return True
        elif t.kind == OP and t.text == "," and depth == 1:
            return False
    return False


def check(ir: FileIR) -> list[Finding]:
    out: list[Finding] = []
    for body in iter_bodies(ir):
        for s in body.stmts:
            toks = s.tokens
            for i, t in enumerate(toks):
                if (
                    t.kind == IDENT
                    and t.text in _TO_DATE
                    and i + 1 < len(toks)
                    and toks[i + 1].text == "("
                    and not (i and toks[i - 1].text == ".")
                    and _single_argument(toks, i + 1)
                ):
                    out.append(
                        Finding(
                            "PLL006",
                            "low",
                            Location(ir.path, t.line, t.col),
                            f"{t.text.upper()} without a format mask depends on NLS settings",
                            "Without a format mask the conversion uses the session's "
                            "NLS_DATE_FORMAT and fails or changes meaning when that differs.",
                            "Pass an explicit format mask, e.g. TO_DATE(x, 'YYYY-MM-DD').",
                            body.name,
                        )
                    )
            if s.kind in _SQL_KINDS:
                continue
            for i in range(1, len(toks) - 1):
                op = toks[i]
                if op.kind != OP or op.text not in _COMPARE:
                    continue
                left, right = toks[i - 1], toks[i + 1]
                if i >= 2 and toks[i - 2].text in (".", ")"):
                    continue
                if i + 2 < len(toks) and toks[i + 2].text in (".", "(", "%", "||"):
                    continue
                fl = _operand_family(left, body.local_types)
                fr = _operand_family(right, body.local_types)
                if fl and fr and fl != fr:
                    out.append(
                        Finding(
                            "PLL006",
                            "low",
                            Location(ir.path, op.line, op.col),
                            f"Implicit conversion: comparing {fl} with {fr}",
                            "Comparing operands of different types makes Oracle convert one side "
                            "implicitly, which can fail at run time or defeat an index.",
                            "Convert explicitly (TO_NUMBER/TO_CHAR/TO_DATE) or fix the types.",
                            body.name,
                        )
                    )
    return out


RULE = Rule("PLL006", "low", "Implicit conversions", check)
