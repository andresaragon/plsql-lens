"""Conservative Oracle→PostgreSQL rewrites of SQL text (F5b).

``rewrite_sql`` applies four mechanical rewrites, identified by the migration rule ids:

* MIG001 ``NVL(a, b)`` → ``COALESCE(a, b)``
* MIG002 ``DECODE(e, s1, r1, …, d)`` → ``CASE e WHEN s1 THEN r1 … ELSE d END``; when a search value
  is the literal ``NULL`` (``DECODE`` matches NULL with NULL) the form is
  ``CASE WHEN e IS NULL THEN … WHEN e = s THEN …``
* MIG004 ``seq.NEXTVAL`` / ``sch.seq.CURRVAL`` → ``nextval('seq')`` / ``currval('sch.seq')``
* MIG010 ``SELECT … FROM DUAL`` → the ``FROM DUAL`` is dropped

The function never rewrites half of a construct. When it cannot rewrite one (unbalanced
parentheses, a comment inside it, an impossible number of arguments, a ``DUAL`` with an alias or in
a join, a remote sequence, …) it leaves that span exactly as it was and says why in ``skipped``.
Text outside the rewritten spans is copied byte for byte.

Constructs are located with ``parser.lexer.tokenize``, which drops comments and keeps no offsets, so
each token's span is computed from its line and column in the original text. Strings, comments and
quoted identifiers are never matched.
"""

from __future__ import annotations

import re
from dataclasses import dataclass

from ..parser.lexer import IDENT, OP, tokenize


@dataclass(frozen=True, slots=True)
class Rewrite:
    sql: str  # the resulting SQL
    applied: tuple[str, ...]  # rule ids applied, one per rewritten construct, in source order
    skipped: tuple[tuple[str, str], ...]  # (rule id, reason) of constructs seen and left alone


_IDENT_RE = re.compile(r"[A-Za-z_][\w$#]*")
_QIDENT_RE = re.compile(r'"[^"\n]*"?')
# What may follow ``FROM DUAL`` for dropping it to be safe (no alias, join list or other clause).
_AFTER_DUAL = frozenset(
    {
        "where",
        "group",
        "having",
        "order",
        "union",
        "intersect",
        "except",
        "fetch",
        "limit",
        "offset",
    }
)
_MAX_PASSES = 10


@dataclass(slots=True)
class _Edit:
    start: int
    end: int
    text: str
    next_k: int  # token index where scanning resumes


class _Pass:
    """One left-to-right pass over ``src``."""

    def __init__(self, src: str) -> None:
        self.src = src
        self.toks = tokenize(src)
        self.applied: list[str] = []
        self.skipped: list[tuple[str, str]] = []
        self.valid = self._locate()

    # -- token spans -----------------------------------------------------------------------
    def _locate(self) -> bool:
        line_starts = [0] + [m.end() for m in re.finditer("\n", self.src)]
        self.starts: list[int] = []
        self.ends: list[int] = []
        for t in self.toks:
            if not 1 <= t.line <= len(line_starts):
                return False
            start = line_starts[t.line - 1] + t.col - 1
            if t.kind == IDENT and self.src[start : start + 1] == '"':
                m = _QIDENT_RE.match(self.src, start)
                end = m.end() if m else start
                ok = m is not None and self.src[start:end].strip('"') == t.text
            elif t.kind == IDENT:
                m = _IDENT_RE.match(self.src, start)
                end = m.end() if m else start
                ok = m is not None and self.src[start:end].lower() == t.text
            else:
                end = start + len(t.text)
                ok = self.src[start:end] == t.text
            if not ok:
                return False
            self.starts.append(start)
            self.ends.append(end)
        return True

    # -- small predicates ------------------------------------------------------------------
    def _op(self, i: int, text: str, hi: int) -> bool:
        return 0 <= i < hi and self.toks[i].kind == OP and self.toks[i].text == text

    def _word(self, i: int, word: str, hi: int) -> bool:
        """An unquoted identifier spelled ``word`` (a quoted ``"nvl"`` is a user's name)."""
        return (
            0 <= i < hi
            and self.toks[i].kind == IDENT
            and self.toks[i].text == word
            and self.src[self.starts[i]] != '"'
        )

    def _clean(self, i: int, j: int) -> bool:
        """Only whitespace between tokens i..j (no comment, directive or SQL*Plus line)."""
        return all(
            not (gap := self.src[self.ends[k] : self.starts[k + 1]]) or gap.isspace()
            for k in range(i, j)
        )

    def _close(self, open_idx: int, hi: int) -> int | None:
        depth = 0
        for k in range(open_idx, hi):
            t = self.toks[k]
            if t.kind == OP and t.text == "(":
                depth += 1
            elif t.kind == OP and t.text == ")":
                depth -= 1
                if depth == 0:
                    return k
        return None

    def _args(self, open_idx: int, close_idx: int) -> list[tuple[int, int]]:
        """Token ranges ``[lo, hi)`` of the call's arguments (split at its own nesting level)."""
        args: list[tuple[int, int]] = []
        depth, lo = 0, open_idx + 1
        for k in range(open_idx + 1, close_idx):
            t = self.toks[k]
            if t.kind == OP and t.text == "(":
                depth += 1
            elif t.kind == OP and t.text == ")":
                depth -= 1
            elif t.kind == OP and t.text == "," and depth == 0:
                args.append((lo, k))
                lo = k + 1
        args.append((lo, close_idx))
        return args

    def _skip(self, rule: str, reason: str) -> None:
        self.skipped.append((rule, reason))

    # -- the scan --------------------------------------------------------------------------
    def emit(self, lo: int, hi: int, off_lo: int, off_hi: int) -> str:
        """``src[off_lo:off_hi]`` with the rewrites of the constructs that start in ``[lo, hi)``."""
        out: list[str] = []
        cursor, k = off_lo, lo
        while k < hi:
            edit = self._try(k, lo, hi)
            if edit is None or edit.start < cursor:
                k += 1
                continue
            out.append(self.src[cursor : edit.start])
            out.append(edit.text)
            cursor, k = edit.end, edit.next_k
        out.append(self.src[cursor:off_hi])
        return "".join(out)

    def _try(self, k: int, lo: int, hi: int) -> _Edit | None:
        t = self.toks[k]
        if t.kind != IDENT:
            return None
        if self._word(k, "from", hi) and self._word(k + 1, "dual", hi):
            return self._from_dual(k, lo, hi)
        if self._op(k + 1, "(", hi) and not self._op(k - 1, ".", hi) and k - 1 >= lo - 1:
            if self._word(k, "nvl", hi):
                return self._nvl(k, hi)
            if self._word(k, "decode", hi):
                return self._decode(k, hi)
        if not self._op(k - 1, ".", hi):
            return self._sequence(k, hi)
        return None

    # -- MIG001 ----------------------------------------------------------------------------
    def _nvl(self, k: int, hi: int) -> _Edit | None:
        close = self._close(k + 1, hi)
        if close is None:
            self._skip("MIG001", "unbalanced parentheses")
            return None
        args = self._args(k + 1, close)
        if len(args) != 2 or any(a == b for a, b in args):
            self._skip("MIG001", "NVL needs exactly two arguments")
            return None
        self.applied.append("MIG001")
        word = self.src[self.starts[k] : self.ends[k]]
        # Only the name changes: the arguments are scanned on, so nested constructs are rewritten.
        return _Edit(self.starts[k], self.ends[k], _like(word, "coalesce"), k + 1)

    # -- MIG002 ----------------------------------------------------------------------------
    def _simple(self, lo: int, hi: int) -> bool:
        """No call, sequence or subquery: evaluating the expression twice changes nothing."""
        for i in range(lo, hi):
            if self.toks[i].kind != IDENT:
                continue
            if self._op(i + 1, "(", hi):
                return False
            if any(self._word(i, w, hi) for w in ("select", "nextval", "currval")):
                return False
        return True

    def _decode(self, k: int, hi: int) -> _Edit | None:
        close = self._close(k + 1, hi)
        if close is None:
            self._skip("MIG002", "unbalanced parentheses")
            return None
        args = self._args(k + 1, close)
        if any(a == b for a, b in args):
            self._skip("MIG002", "empty argument")
            return None
        if len(args) < 3:
            self._skip("MIG002", "DECODE needs at least three arguments")
            return None
        if not self._clean(k, close):
            self._skip("MIG002", "comment inside the construct")
            return None
        pairs = (len(args) - 1) // 2
        has_default = (len(args) - 1) % 2 == 1
        null_search = {
            j
            for j in range(pairs)
            if args[1 + 2 * j][1] - args[1 + 2 * j][0] == 1
            and self._word(args[1 + 2 * j][0], "null", hi)
        }
        subject = args[0]
        # An untyped NULL after CASE is text on PostgreSQL (`CASE NULL WHEN 1` fails to compile).
        null_subject = subject[1] - subject[0] == 1 and self._word(subject[0], "null", hi)
        when_form = bool(null_search) or null_subject
        if null_search and not self._simple(*subject):
            self._skip("MIG002", "NULL search value on a non-simple expression (evaluated twice)")
            return None
        self.applied.append("MIG002")
        word = self.src[self.starts[k] : self.ends[k]]
        lower = word.islower()

        def kw(w: str) -> str:
            return w if lower else w.upper()

        def text(r: tuple[int, int]) -> str:
            return self.emit(r[0], r[1], self.starts[r[0]], self.ends[r[1] - 1])

        def atom(r: tuple[int, int]) -> str:
            return text(r) if r[1] - r[0] == 1 else f"({text(r)})"

        parts = [kw("case")]
        if not when_form:
            parts.append(text(subject))
        for j in range(pairs):
            search, result = args[1 + 2 * j], args[2 + 2 * j]
            parts.append(kw("when"))
            if not when_form:
                parts.append(text(search))
            elif j in null_search:
                parts.append(f"{atom(subject)} {kw('is')} {kw('null')}")
            else:
                parts.append(f"{atom(subject)} = {atom(search)}")
            parts += [kw("then"), text(result)]
        if has_default:
            parts += [kw("else"), text(args[-1])]
        parts.append(kw("end"))
        return _Edit(self.starts[k], self.ends[close], " ".join(parts), close + 1)

    # -- MIG004 ----------------------------------------------------------------------------
    def _sequence(self, k: int, hi: int) -> _Edit | None:
        parts = [k]
        while (
            self._op(parts[-1] + 1, ".", hi)
            and parts[-1] + 2 < hi
            and self.toks[parts[-1] + 2].kind == IDENT
        ):
            parts.append(parts[-1] + 2)
        last = parts[-1]
        if len(parts) < 2 or not (
            self._word(last, "nextval", hi) or self._word(last, "currval", hi)
        ):
            return None
        if not self._clean(k, last):
            self._skip("MIG004", "comment inside the construct")
            return None
        if self._op(last + 1, "@", len(self.toks)):
            self._skip("MIG004", "remote sequence (database link)")
            return None
        name = ".".join(self.src[self.starts[p] : self.ends[p]] for p in parts[:-1])
        if "'" in name:
            self._skip("MIG004", "quote in the sequence name")
            return None
        self.applied.append("MIG004")
        text = f"{self.toks[last].text}('{name}')"
        return _Edit(self.starts[k], self.ends[last], text, last + 1)

    # -- MIG010 ----------------------------------------------------------------------------
    def _from_dual(self, k: int, lo: int, hi: int) -> _Edit | None:
        prev = self.toks[k - 1] if k - 1 >= lo else None
        if prev is None or self._word(k - 1, "delete", hi) or self._word(k - 1, "merge", hi):
            self._skip("MIG010", "FROM DUAL is not the end of a select list")
            return None
        if prev.kind == OP and prev.text == "*":
            self._skip("MIG010", "SELECT * needs a table in PostgreSQL")
            return None
        nxt = k + 2
        follows_ok = (
            nxt >= hi
            or self._op(nxt, ";", hi)
            or self._op(nxt, ")", hi)
            or any(self._word(nxt, w, hi) for w in _AFTER_DUAL)
        )
        if not follows_ok:
            self._skip("MIG010", "DUAL has an alias, is joined or is followed by another clause")
            return None
        if not self._clean(k - 1, k + 1):
            self._skip("MIG010", "comment inside the construct")
            return None
        self.applied.append("MIG010")
        return _Edit(self.ends[k - 1], self.ends[k + 1], "", k + 2)


def _like(word: str, replacement: str) -> str:
    """``replacement`` in lower case if ``word`` is all lower case, else in upper case."""
    return replacement if word.islower() else replacement.upper()


def rewrite_sql(sql: str) -> Rewrite:
    """Rewrite the Oracle constructs in ``sql`` that can be rewritten mechanically and safely.

    Idempotent: a second pass runs only if the first changed something, until nothing changes (odd
    input can make a rewrite expose a new match, e.g. ``from dual from dual``).
    """
    applied: list[str] = []
    skipped: list[tuple[str, str]] = []
    text = sql
    for n in range(_MAX_PASSES):
        p = _Pass(text)
        if not p.valid:  # pragma: no cover - the lexer and the offsets always agree
            return Rewrite(sql, (), (("MIG000", "token positions do not match the text"),))
        new = p.emit(0, len(p.toks), 0, len(text))
        if n == 0:
            skipped = p.skipped
        applied += p.applied
        if not p.applied or new == text:
            break
        text = new
    return Rewrite(text, tuple(applied), tuple(skipped))
