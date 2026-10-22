"""Structural recursive-descent parser: PL/SQL source -> IR (units, params, call sites).

It understands only the structure the inventory and rules need (units, subprogram
headers, parameter lists, block nesting, call-site candidates) and skips everything
else token by token, so unknown syntax never aborts a file.
"""

from __future__ import annotations

from collections.abc import Iterable

from .ir import Call, FileIR, Param, ParseIssue, Subprogram, Unit
from .lexer import IDENT, OP, Token, tokenize

_MODES = {"in", "out", "nocopy"}
_CREATE_MODS = {"or", "replace", "editionable", "noneditionable", "force", "noforce"}
_NOT_CALL = frozenset(
    [
        "if",
        "elsif",
        "then",
        "else",
        "loop",
        "end",
        "begin",
        "case",
        "when",
        "while",
        "for",
        "in",
        "is",
        "as",
        "return",
        "exception",
        "not",
        "and",
        "or",
        "null",
        "true",
        "false",
        "select",
        "from",
        "where",
        "into",
        "values",
        "set",
        "update",
        "insert",
        "delete",
        "merge",
        "union",
        "all",
        "exit",
        "continue",
        "goto",
        "raise",
        "open",
        "close",
        "fetch",
        "pragma",
        "declare",
        "using",
        "out",
        "like",
        "between",
        "exists",
        "any",
        "some",
        "by",
        "order",
        "group",
        "having",
        "join",
        "on",
        "cursor",
        "type",
        "constant",
        "of",
        "default",
        "new",
        "bulk",
        "collect",
        "forall",
        "save",
        "exceptions",
        "rowtype",
        "subtype",
        "record",
        "table",
        "index",
        "cast",
    ]
)


class _Eof(Exception):
    pass


class _Parser:
    def __init__(self, toks: list[Token]) -> None:
        self.t = toks
        self.i = 0
        self.issues: list[ParseIssue] = []

    # -- token helpers ---------------------------------------------------
    def peek(self, k: int = 0) -> Token | None:
        j = self.i + k
        return self.t[j] if j < len(self.t) else None

    def is_kw(self, word: str, k: int = 0) -> bool:
        tok = self.peek(k)
        return tok is not None and tok.kind == IDENT and tok.text == word

    def is_op(self, text: str, k: int = 0) -> bool:
        tok = self.peek(k)
        return tok is not None and tok.kind == OP and tok.text == text

    def issue(self, message: str, tok: Token | None = None) -> None:
        tok = tok or self.peek() or (self.t[-1] if self.t else None)
        self.issues.append(ParseIssue(tok.line if tok else 1, message))

    def skip_parens(self) -> None:
        """Skip a balanced ``( ... )`` starting at the current ``(``."""
        depth = 0
        while self.i < len(self.t):
            tok = self.t[self.i]
            self.i += 1
            if tok.kind == OP:
                if tok.text == "(":
                    depth += 1
                elif tok.text == ")":
                    depth -= 1
                    if depth == 0:
                        return

    def skip_to_semicolon(self) -> None:
        """Skip a declaration up to and including its ``;`` at paren depth 0."""
        depth = 0
        while self.i < len(self.t):
            tok = self.t[self.i]
            self.i += 1
            if tok.kind == OP:
                if tok.text == "(":
                    depth += 1
                elif tok.text == ")":
                    depth = max(0, depth - 1)
                elif tok.text == ";" and depth == 0:
                    return

    def read_name(self) -> str | None:
        """Read ``[schema.]name`` and return the last part."""
        tok = self.peek()
        if tok is None or tok.kind != IDENT:
            return None
        name = tok.text
        self.i += 1
        while self.is_op(".") and (nxt := self.peek(1)) is not None and nxt.kind == IDENT:
            name = nxt.text
            self.i += 2
        return name

    # -- parameters ------------------------------------------------------
    def parse_params(self) -> tuple[Param, ...]:
        start = self.i
        self.skip_parens()
        inner = self.t[start + 1 : self.i - 1]
        groups: list[list[Token]] = [[]]
        depth = 0
        for tok in inner:
            if tok.kind == OP and tok.text == "(":
                depth += 1
            elif tok.kind == OP and tok.text == ")":
                depth -= 1
            if tok.kind == OP and tok.text == "," and depth == 0:
                groups.append([])
            else:
                groups[-1].append(tok)
        params = []
        for g in groups:
            if not g or g[0].kind != IDENT:
                continue
            name, rest = g[0].text, g[1:]
            modes: list[str] = []
            while rest and rest[0].kind == IDENT and rest[0].text in _MODES:
                modes.append(rest[0].text)
                rest = rest[1:]
            has_default = False
            type_toks = []
            for tok in rest:
                if (tok.kind == OP and tok.text == ":=") or (
                    tok.kind == IDENT and tok.text == "default"
                ):
                    has_default = True
                    break
                type_toks.append(tok)
            mode = (
                "in out" if "in" in modes and "out" in modes else "out" if "out" in modes else "in"
            )
            if "out" in modes and "in" not in modes:
                mode = "out"
            params.append(Param(name, mode, _join(type_toks), has_default))
        return tuple(params)

    # -- subprograms -----------------------------------------------------
    def parse_subprogram(self, depth: int = 0) -> Subprogram | None:
        """At ``procedure|function``: parse header and (if present) body."""
        kw = self.t[self.i]
        self.i += 1
        name = self.read_name()
        if name is None:
            return None
        params: tuple[Param, ...] = ()
        if self.is_op("("):
            params = self.parse_params()
        return_type: str | None = None
        if self.is_kw("return"):
            self.i += 1
            rt = []
            while (tok := self.peek()) is not None:
                if tok.kind == OP and tok.text in (";", ","):
                    break
                prev = self.t[self.i - 1]
                if tok.kind == IDENT and tok.text == "as" and prev.text == "self":
                    self.i += 2  # RETURN SELF AS RESULT
                    continue
                if tok.kind == IDENT and tok.text in (
                    "is",
                    "as",
                    "deterministic",
                    "pipelined",
                    "result_cache",
                    "parallel_enable",
                    "authid",
                    "accessible",
                    "aggregate",
                    "using",
                ):
                    break
                if tok.kind == OP and tok.text == "(":
                    start = self.i
                    self.skip_parens()
                    rt.extend(self.t[start : self.i])
                    continue
                rt.append(tok)
                self.i += 1
            return_type = _join(rt)
        # trailing clauses up to ';' (declaration only) or IS/AS (body)
        while (tok := self.peek()) is not None:
            if tok.kind == OP and tok.text == ";":
                self.i += 1
                return Subprogram(kw.text, name, params, return_type, kw.line, False)
            if tok.kind == IDENT and tok.text in ("is", "as"):
                break
            if tok.kind == OP and tok.text == "(":
                self.skip_parens()
                continue
            self.i += 1
        else:
            self.issue(f"unexpected end of file in header of {name}", kw)
            return Subprogram(kw.text, name, params, return_type, kw.line, False)
        self.i += 1  # IS / AS
        if self.is_kw("language") or self.is_kw("external"):
            self.skip_to_semicolon()
            return Subprogram(kw.text, name, params, return_type, kw.line, True)
        calls: list[Call] = []
        nested, names = self.parse_declarations(calls, depth + 1)
        self.parse_block_body(calls, name)
        local = frozenset(names | {p.name for p in params})
        return Subprogram(
            kw.text, name, params, return_type, kw.line, True, tuple(calls), nested, local
        )

    def parse_declarations(
        self, calls: list[Call], depth: int
    ) -> tuple[tuple[Subprogram, ...], set[str]]:
        """Declarative part up to (not including) ``BEGIN``/``END``.

        Returns the nested subprograms and the names declared locally.
        """
        nested: list[Subprogram] = []
        names: set[str] = set()
        while (tok := self.peek()) is not None:
            if tok.kind == IDENT and tok.text in ("begin", "end"):
                break
            if tok.kind == IDENT and tok.text in ("procedure", "function"):
                sp = self.parse_subprogram(depth)
                if sp is not None:
                    nested.append(sp)
                    names.add(sp.name)
                continue
            start = self.i
            self.skip_to_semicolon()
            _collect_calls(self.t[start : self.i], calls)
            first = self.t[start]
            if first.kind == IDENT and first.text not in ("cursor", "type", "subtype", "pragma"):
                names.add(first.text)
        return tuple(nested), names

    def parse_block_body(self, calls: list[Call], name: str) -> None:
        """At ``BEGIN``: consume through the matching ``END [name];``, collecting calls."""
        tok = self.peek()
        if tok is None:
            self.issue(f"unexpected end of file in body of {name}")
            return
        if not (tok.kind == IDENT and tok.text == "begin"):
            self.issue(f"expected BEGIN in {name}", tok)
            return
        stack = ["begin"]
        self.i += 1
        start = self.i
        while self.i < len(self.t):
            tok = self.t[self.i]
            if tok.kind == IDENT:
                w = tok.text
                if w == "end":
                    nxt = self.peek(1)
                    if nxt is not None and nxt.kind == IDENT and nxt.text in ("if", "loop", "case"):
                        if stack and stack[-1] == nxt.text:
                            stack.pop()
                        self.i += 2
                        continue
                    if stack:
                        stack.pop()
                    self.i += 1
                    if not stack:
                        _collect_calls(self.t[start : self.i - 1], calls)
                        # optional label, then ';'
                        while (t2 := self.peek()) is not None and not (
                            t2.kind == OP and t2.text == ";"
                        ):
                            self.i += 1
                        self.i += 1
                        return
                    continue
                if w in ("begin", "if", "loop", "case"):
                    prev = self.t[self.i - 1] if self.i else None
                    if w == "if" and prev is not None and prev.kind == IDENT and prev.text == "end":
                        pass
                    else:
                        stack.append(w)
                elif w == "declare":
                    pass
            self.i += 1
        self.issue(f"unterminated body of {name}", self.t[start - 1])
        _collect_calls(self.t[start:], calls)

    # -- package / type / top-level ---------------------------------------
    def parse_package(self, body: bool, line: int, name: str) -> Unit:
        # skip AUTHID / ACCESSIBLE BY ... up to IS|AS
        while (tok := self.peek()) is not None and not (
            tok.kind == IDENT and tok.text in ("is", "as")
        ):
            if tok.kind == OP and tok.text == "(":
                self.skip_parens()
            else:
                self.i += 1
        self.i += 1
        subs: list[Subprogram] = []
        init_calls: list[Call] = []
        while (tok := self.peek()) is not None:
            if tok.kind == IDENT and tok.text == "end":
                self.i += 1
                self.skip_to_semicolon()
                return Unit(
                    "package_body" if body else "package",
                    name,
                    line,
                    subprograms=tuple(subs),
                    calls=tuple(init_calls),
                )
            if tok.kind == IDENT and tok.text == "begin" and body:
                self.parse_block_body(init_calls, name)
                return Unit(
                    "package_body", name, line, subprograms=tuple(subs), calls=tuple(init_calls)
                )
            if tok.kind == IDENT and tok.text in ("procedure", "function"):
                sp = self.parse_subprogram()
                if sp is not None:
                    subs.append(sp)
                continue
            start = self.i
            self.skip_to_semicolon()
            _collect_calls(self.t[start : self.i], init_calls)
        self.issue(f"unexpected end of file in package {name}", self.t[-1] if self.t else None)
        return Unit(
            "package_body" if body else "package",
            name,
            line,
            subprograms=tuple(subs),
            calls=tuple(init_calls),
        )

    def parse_type(self, body: bool, line: int, name: str) -> Unit:
        subs: list[Subprogram] = []
        if not body:
            # object type spec: members are comma separated inside the outer parentheses
            while (tok := self.peek()) is not None and not (
                tok.kind == OP and tok.text in ("(", ";")
            ):
                self.i += 1
            if self.is_op("("):
                end = self.i
                self.skip_parens()
                inner = self.t[end : self.i]
                depth = 0
                for j, tok in enumerate(inner):
                    if tok.kind == OP and tok.text == "(":
                        depth += 1
                    elif tok.kind == OP and tok.text == ")":
                        depth -= 1
                    elif (
                        depth == 1
                        and tok.kind == IDENT
                        and tok.text in ("procedure", "function")
                        and j + 1 < len(inner)
                        and inner[j + 1].kind == IDENT
                    ):
                        subs.append(
                            Subprogram(tok.text, inner[j + 1].text, (), None, tok.line, False)
                        )
            self.skip_to_semicolon_or_slash()
            return Unit("type", name, line, subprograms=tuple(subs))
        while (tok := self.peek()) is not None and not (
            tok.kind == IDENT and tok.text in ("is", "as")
        ):
            self.i += 1
        self.i += 1
        while (tok := self.peek()) is not None:
            if tok.kind == IDENT and tok.text == "end":
                self.i += 1
                self.skip_to_semicolon()
                return Unit("type_body", name, line, subprograms=tuple(subs))
            if tok.kind == IDENT and tok.text in ("procedure", "function"):
                sp = self.parse_subprogram()
                if sp is not None:
                    subs.append(sp)
                continue
            self.i += 1
        self.issue(f"unexpected end of file in type body {name}", self.t[-1] if self.t else None)
        return Unit("type_body", name, line, subprograms=tuple(subs))

    def skip_to_semicolon_or_slash(self) -> None:
        self.skip_to_semicolon()

    def parse_standalone(self, kind: str, line: int, name: str) -> Unit:
        params: tuple[Param, ...] = ()
        if self.is_op("("):
            params = self.parse_params()
        return_type = None
        if self.is_kw("return"):
            self.i += 1
            rt = []
            while (
                (tok := self.peek()) is not None
                and not (
                    tok.kind == IDENT
                    and tok.text
                    in (
                        "is",
                        "as",
                        "deterministic",
                        "pipelined",
                        "result_cache",
                        "authid",
                        "parallel_enable",
                    )
                )
                and not (tok.kind == OP and tok.text == ";")
            ):
                rt.append(tok)
                self.i += 1
            return_type = _join(rt)
        while (tok := self.peek()) is not None and not (
            tok.kind == IDENT and tok.text in ("is", "as")
        ):
            if tok.kind == OP and tok.text == "(":
                self.skip_parens()
            elif tok.kind == OP and tok.text == ";":
                break
            else:
                self.i += 1
        calls: list[Call] = []
        if self.is_kw("is") or self.is_kw("as"):
            self.i += 1
            if self.is_kw("language") or self.is_kw("external"):
                self.skip_to_semicolon()
            else:
                nested, names = self.parse_declarations(calls, 1)
                self.parse_block_body(calls, name)
                return Unit(
                    kind,
                    name,
                    line,
                    params,
                    return_type,
                    nested,
                    tuple(calls),
                    frozenset(names | {p.name for p in params}),
                )
        else:
            self.skip_to_semicolon()
        return Unit(kind, name, line, params, return_type, calls=tuple(calls))

    def parse_trigger(self, line: int, name: str) -> Unit:
        calls: list[Call] = []
        while (tok := self.peek()) is not None and not (
            tok.kind == IDENT and tok.text in ("declare", "begin", "compound", "call")
        ):
            if tok.kind == OP and tok.text == "(":
                self.skip_parens()
            else:
                self.i += 1
        if self.is_kw("compound"):
            self.i += 2
            subs: list[Subprogram] = []
            while (tok := self.peek()) is not None:
                if tok.kind == IDENT and tok.text == "end":
                    self.i += 1
                    self.skip_to_semicolon()
                    break
                self.i += 1
            return Unit("trigger", name, line, subprograms=tuple(subs))
        if self.is_kw("call"):
            start = self.i
            self.skip_to_semicolon()
            _collect_calls(self.t[start : self.i], calls)
            return Unit("trigger", name, line, calls=tuple(calls))
        nested: tuple[Subprogram, ...] = ()
        names: set[str] = set()
        if self.is_kw("declare"):
            self.i += 1
            nested, names = self.parse_declarations(calls, 1)
        self.parse_block_body(calls, name)
        return Unit(
            "trigger", name, line, subprograms=nested, calls=tuple(calls), locals=frozenset(names)
        )

    def parse_file(self) -> list[Unit]:
        units: list[Unit] = []
        while self.i < len(self.t):
            tok = self.t[self.i]
            if not (tok.kind == IDENT and tok.text == "create"):
                self.i += 1
                continue
            self.i += 1
            while (t2 := self.peek()) is not None and t2.kind == IDENT and t2.text in _CREATE_MODS:
                self.i += 1
            t2 = self.peek()
            if t2 is None or t2.kind != IDENT:
                continue
            what = t2.text
            line = tok.line
            if what in ("package", "type"):
                self.i += 1
                body = self.is_kw("body")
                if body:
                    self.i += 1
                name = self.read_name()
                if name is None:
                    continue
                try:
                    units.append(
                        self.parse_package(body, line, name)
                        if what == "package"
                        else self.parse_type(body, line, name)
                    )
                except _Eof:  # pragma: no cover
                    self.issue(f"unexpected end of file in {what} {name}")
            elif what in ("procedure", "function"):
                self.i += 1
                name = self.read_name()
                if name is not None:
                    units.append(self.parse_standalone(what, line, name))
            elif what == "trigger":
                self.i += 1
                name = self.read_name()
                if name is not None:
                    units.append(self.parse_trigger(line, name))
        return units


def _join(toks: Iterable[Token]) -> str:
    out = ""
    for tok in toks:
        if tok.kind == IDENT and out and out[-1].isalnum():
            out += " "
        out += tok.text
    return out


def _collect_calls(toks: list[Token], out: list[Call]) -> None:
    """Add dotted identifier chains followed by ``(`` or ``;`` (candidate calls)."""
    n, i = len(toks), 0
    while i < n:
        tok = toks[i]
        if tok.kind != IDENT or (
            i and toks[i - 1].kind == OP and toks[i - 1].text in (".", "%", ":", "@")
        ):
            i += 1
            continue
        chain = [tok.text]
        j = i + 1
        while (
            j + 1 < n and toks[j].kind == OP and toks[j].text == "." and toks[j + 1].kind == IDENT
        ):
            chain.append(toks[j + 1].text)
            j += 2
        nxt = toks[j] if j < n else None
        follow = (
            nxt.text if nxt is not None and nxt.kind == OP and nxt.text in ("(", ";") else "other"
        )
        prev_kw = (
            i > 0
            and toks[i - 1].kind == IDENT
            and toks[i - 1].text in ("type", "exception", "cursor")
        )
        if (
            (chain[0] not in _NOT_CALL or len(chain) > 1)
            and not prev_kw
            and not (nxt is not None and nxt.kind == OP and nxt.text in (":=", "=>", "%"))
            and not (follow == ";" and len(chain) == 1 and i > 0 and _is_decl_ctx(toks, i))
        ):
            out.append(Call(tuple(chain), tok.line, tok.col, follow))
        i = j


def _is_decl_ctx(toks: list[Token], i: int) -> bool:
    """``name;`` right after a type-like word is a declaration end, not a call."""
    return toks[i - 1].kind == IDENT and toks[i - 1].text in ("exception", "pragma", "of", "is")


def parse_source(src: str, path: str = "<memory>") -> FileIR:
    toks = tokenize(src)
    parser = _Parser(toks)
    units = parser.parse_file()
    return FileIR(path, src.count("\n") + 1, tuple(units), tuple(parser.issues))
