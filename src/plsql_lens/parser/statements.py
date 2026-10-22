"""Statement layer: split a PL/SQL block body into flat statements with their scope context.

This is deliberately not an AST. Each statement keeps its tokens and the stack of enclosing
constructs (``loop``, ``if``, ``case``, ``begin``, ``handler:<names>``), which is what the review
rules need. Block headers (``IF .. THEN``, ``FOR .. LOOP``, ``WHEN .. THEN``) are statements of
their own kind so that, for example, a cursor FOR-loop header can be inspected.
"""

from __future__ import annotations

from .ir import Stmt
from .lexer import IDENT, OP, Token

_DML = {"insert": "insert", "update": "update", "delete": "delete", "merge": "merge"}
_SIMPLE = frozenset(
    [
        "commit",
        "rollback",
        "savepoint",
        "raise",
        "return",
        "exit",
        "continue",
        "null",
        "goto",
        "close",
        "fetch",
        "pipe",
    ]
)
_OPENERS = ("begin", "loop", "if", "case")


def _is(tok: Token, *words: str) -> bool:
    return tok.kind == IDENT and tok.text in words


def _paren_depth_scan(toks: list[Token], stop: str) -> int:
    """Index of the first ``stop`` word at paren depth 0 and outside expression CASEs, or -1."""
    depth = case = 0
    for i, t in enumerate(toks):
        if t.kind == OP and t.text == "(":
            depth += 1
        elif t.kind == OP and t.text == ")":
            depth -= 1
        elif t.kind == IDENT and depth == 0:
            if t.text == "case":
                case += 1
            elif t.text == "end" and case:
                case -= 1
            elif t.text == stop and case == 0:
                return i
    return -1


def classify(toks: list[Token]) -> str:
    """Kind of a complete (``;``-terminated, header-free) statement."""
    first = toks[0]
    if first.kind != IDENT:
        return "other"
    w = first.text
    if w in ("select", "with"):
        if _paren_depth_scan(toks, "into") < 0:
            return "select"
        bulk = any(
            _is(toks[i], "bulk") and i + 1 < len(toks) and _is(toks[i + 1], "collect")
            for i in range(len(toks))
        )
        return "select_bulk" if bulk else "select_into"
    if w in _DML:
        return "dml"
    if w == "execute" and len(toks) > 1 and _is(toks[1], "immediate"):
        return "execute_immediate"
    if w == "open":
        return "open_for" if any(_is(t, "for") for t in toks) else "open"
    if w == "forall":
        return "forall"
    if w in _SIMPLE:
        return w
    # assignment or call: dotted chain, optional (args) / subscripts, then := or ( or ;
    i = 0
    while i < len(toks) and toks[i].kind == IDENT:
        i += 1
        if i < len(toks) and toks[i].kind == OP and toks[i].text == ".":
            i += 1
            continue
        break
    depth = 0
    for t in toks[i:]:
        if t.kind == OP and t.text == "(":
            depth += 1
        elif t.kind == OP and t.text == ")":
            depth -= 1
        elif depth == 0 and t.kind == OP and t.text == ":=":
            return "assign"
        elif depth == 0 and t.kind == OP and t.text in (";", "=>"):
            break
    if i == len(toks) or (toks[i].kind == OP and toks[i].text in ("(", ";")):
        return "call"
    return "other"


def split_statements(toks: list[Token]) -> tuple[Stmt, ...]:
    """Split the tokens between a body's ``BEGIN`` and its final ``END`` into statements."""
    out: list[Stmt] = []
    stack: list[str] = ["begin"]  # root block, hidden from contexts
    sid: list[int] = [0]  # parallel to ``stack``: block id for BEGIN entries, -1 otherwise
    next_block = 1
    in_exc: set[int] = set()  # stack depths whose block reached its EXCEPTION section
    cur: list[Token] = []
    expr_case = 0
    depth = 0
    n = len(toks)

    def ctx() -> tuple[str, ...]:
        return tuple(stack[1:])

    def emit(kind: str, ts: list[Token], context: tuple[str, ...] | None = None) -> None:
        if ts:
            out.append(
                Stmt(
                    kind,
                    tuple(ts),
                    ctx() if context is None else context,
                    ts[0].line,
                    ts[0].col,
                    tuple(b for b in sid if b >= 0),
                )
            )

    def push(word: str) -> None:
        nonlocal next_block
        stack.append(word)
        if word == "begin":
            sid.append(next_block)
            next_block += 1
        else:
            sid.append(-1)

    def pop() -> None:
        in_exc.discard(len(stack) - 1)
        stack.pop()
        sid.pop()

    def pop_to(word: str) -> None:
        while len(stack) > 1 and stack[-1] != word:
            pop()
        if len(stack) > 1:
            pop()

    def strip_label(ts: list[Token]) -> list[Token]:
        while ts and ts[0].kind == OP and ts[0].text == "<<":
            j = next((k for k, t in enumerate(ts) if t.kind == OP and t.text == ">>"), None)
            if j is None:
                break
            ts = ts[j + 1 :]
        return ts

    i = 0
    while i < n:
        t = toks[i]
        if t.kind == OP:
            if t.text == "(":
                depth += 1
            elif t.text == ")":
                depth -= 1
            elif t.text == ";" and depth <= 0:
                depth = 0
                ts = strip_label(cur)
                if ts:
                    emit(classify(ts), ts)
                cur = []
                expr_case = 0
                i += 1
                continue
            cur.append(t)
            i += 1
            continue
        if t.kind != IDENT or depth > 0:
            cur.append(t)
            i += 1
            continue
        w = t.text
        header_ts = strip_label(cur)
        at_start = not header_ts
        if w == "case" and (not at_start or expr_case):
            expr_case += 1
        elif w == "end" and expr_case:
            expr_case -= 1
        elif at_start and expr_case == 0:
            nxt = toks[i + 1].text if i + 1 < n and toks[i + 1].kind == IDENT else ""
            if w == "end":
                j = i + 1
                while j < n and not (toks[j].kind == OP and toks[j].text == ";"):
                    j += 1
                if nxt in ("if", "loop", "case"):
                    pop_to(nxt)
                else:
                    while len(stack) > 1 and stack[-1].startswith("handler:"):
                        pop()
                    pop_to("begin")
                cur = []
                i = j + 1
                continue
            if w in ("begin", "declare"):
                if w == "begin":
                    push("begin")
                i += 1
                continue
            if w == "exception" and not (cur and _is(cur[-1], "save")):
                in_exc.add(len(stack) - 1)
                i += 1
                continue
            if w == "else":
                i += 1
                continue
            if w == "loop":
                emit("loop", [t])
                push("loop")
                i += 1
                continue
            if w == "case":
                j = i + 1
                k = _paren_depth_scan(toks[j:], "when")
                emit("case", toks[i : j + k] if k >= 0 else [t])
                push("case")
                i = j + (k if k >= 0 else 0)
                continue
            if w in ("if", "elsif", "when", "for", "while"):
                stop = "then" if w in ("if", "elsif", "when") else "loop"
                j = _paren_depth_scan(toks[i + 1 :], stop)
                if j < 0:
                    cur.append(t)
                    i += 1
                    continue
                head = toks[i + 1 : i + 1 + j]
                end = i + 1 + j + 1
                if w == "if":
                    emit("if", head)
                    push("if")
                elif w == "elsif":
                    emit("elsif", head)
                elif w == "when":
                    in_handler = stack[-1].startswith("handler:")
                    if stack[-1] == "case":
                        emit("when", head)
                    elif in_handler or (len(stack) - 1) in in_exc:
                        if in_handler:
                            pop()
                        names = ",".join(x.text for x in head if x.kind == IDENT and x.text != "or")
                        emit("handler", head)
                        push(f"handler:{names}")
                    else:
                        emit("when", head)
                else:
                    emit(f"{w}_loop", [t, *head])
                    push("loop")
                i = end
                continue
        cur.append(t)
        i += 1
    ts = strip_label(cur)
    if ts:
        emit(classify(ts), ts)
    return tuple(out)
