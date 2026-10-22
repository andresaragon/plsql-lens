"""Tolerant PL/SQL lexer: drops comments and conditional-compilation directives."""

from __future__ import annotations

import re
from dataclasses import dataclass

IDENT = "ident"
NUMBER = "number"
STRING = "string"
OP = "op"

_TOKEN_RE = re.compile(
    r"""
    (?P<ws>\s+)
  | (?P<lcomment>--[^\n]*)
  | (?P<bcomment>/\*.*?(?:\*/|\Z))
  | (?P<qstring>[nN]?[qQ]'(?:\[.*?\]|\{.*?\}|\(.*?\)|<.*?>|(?P<qd>[^\s\w]).*?(?P=qd))')
  | (?P<string>[nN]?'(?:[^']|'')*(?:'|\Z))
  | (?P<qident>"[^"\n]*"?)
  | (?P<directive>\$\$?[A-Za-z_]\w*)
  | (?P<ident>[A-Za-z_][\w$#]*)
  | (?P<number>\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)
  | (?P<op>:=|=>|\.\.|\|\||\*\*|<>|!=|~=|\^=|<=|>=|<<|>>|[-+*/=<>(),.;:%@|&!~^\[\]{}?])
  | (?P<other>.)
    """,
    re.VERBOSE | re.DOTALL,
)

# SQL*Plus lines that are neither code nor comments.
_SQLPLUS_RE = re.compile(r"^[ \t]*(rem(?:ark)?|prompt)\b[^\n]*", re.IGNORECASE | re.MULTILINE)
_SQLPLUS_LINE_RE = re.compile(
    r"^[ \t]*(?:set[ \t]+(?:serveroutput|define|echo|feedback|verify|termout|pagesize|linesize|"
    r"sqlblanklines|scan|escape|timing|trimspool|long|heading|head|autotrace|sqlprompt|time|"
    r"sqlterminator|appinfo|numwidth|wrap|colsep|null|recsep|tab|trims|lin|pages|sqlt|"
    r"blockterminator|concat|cmdsep|ver|feed|serveroutput)\b"
    r"|show[ \t]+(?:errors|err|user)\b|spool\b|whenever[ \t]+(?:sql|os)error\b)"
    r"[^\n;]*$",
    re.IGNORECASE | re.MULTILINE,
)


@dataclass(frozen=True, slots=True)
class Token:
    kind: str
    text: str  # identifiers are lowercased, quoted identifiers keep case without quotes
    line: int
    col: int

    @property
    def upper(self) -> str:
        return self.text.upper()


def _blank_sqlplus(src: str) -> str:
    def blank(m: re.Match[str]) -> str:
        return " " * len(m.group(0))

    return _SQLPLUS_LINE_RE.sub(blank, _SQLPLUS_RE.sub(blank, src))


def tokenize(src: str) -> list[Token]:
    """Return significant tokens; ``$if ... $then``, ``$else`` and ``$end`` are removed.

    Both branches of a conditional-compilation block are kept as ordinary code.
    """
    src = _blank_sqlplus(src)
    toks: list[Token] = []
    line, line_start = 1, 0
    skipping_until_then = False
    skipping_until_end = False
    for m in _TOKEN_RE.finditer(src):
        kind = m.lastgroup or "other"
        text = m.group(0)
        start = m.start()
        tok_line, tok_col = line, start - line_start + 1
        nl = text.count("\n")
        if nl:
            line += nl
            line_start = start + text.rfind("\n") + 1
        if kind in ("ws", "lcomment", "bcomment"):
            continue
        if kind == "directive":
            low = text.lower()
            if low in ("$if", "$elsif"):
                skipping_until_then = True
            elif low == "$error":
                skipping_until_end = True
            elif low in ("$then", "$else"):
                skipping_until_then = False
            elif low == "$end":
                skipping_until_end = False
            continue
        if skipping_until_then or skipping_until_end:
            continue
        if kind == "qstring":
            kind = STRING
        if kind == "qident":
            toks.append(Token(IDENT, text.strip('"'), tok_line, tok_col))
        elif kind == "ident":
            toks.append(Token(IDENT, text.lower(), tok_line, tok_col))
        elif kind in (NUMBER, STRING, OP):
            toks.append(Token(kind, text, tok_line, tok_col))
        else:
            toks.append(Token(OP, text, tok_line, tok_col))
    return toks
