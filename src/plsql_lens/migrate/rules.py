"""Migration rules MIG001–MIG011: token checks over the whole file (docs/migration-rules.md)."""

from __future__ import annotations

from collections.abc import Callable, Iterable, Sequence
from dataclasses import replace
from pathlib import Path

from ..parser import FileIR, Subprogram, Unit, parse_source
from ..parser.lexer import IDENT, OP, STRING, Token, tokenize
from ..rules.model import Finding, Location, Rule
from ..rules.suppress import apply_suppressions

# A check sees the tokens of one file and returns (token, message override | None) hits.
Hit = tuple[Token, str | None]
TokenCheck = Callable[[Sequence[Token]], list[Hit]]


def _is(tok: Token | None, kind: str, text: str) -> bool:
    return tok is not None and tok.kind == kind and tok.text == text


def _at(toks: Sequence[Token], i: int) -> Token | None:
    return toks[i] if 0 <= i < len(toks) else None


def _call_indices(toks: Sequence[Token], name: str) -> list[int]:
    """Indices of ``name`` followed by ``(`` and not preceded by ``.``."""
    return [
        i
        for i, t in enumerate(toks)
        if _is(t, IDENT, name)
        and _is(_at(toks, i + 1), OP, "(")
        and not _is(_at(toks, i - 1), OP, ".")
    ]


def _call_of(name: str) -> TokenCheck:
    return lambda toks: [(toks[i], None) for i in _call_indices(toks, name)]


def _split_args(toks: Sequence[Token], open_idx: int) -> list[list[Token]]:
    """Arguments of the call whose ``(`` is at ``open_idx`` (split at its own nesting level)."""
    args: list[list[Token]] = [[]]
    depth = 0
    for t in toks[open_idx:]:
        if t.kind == OP and t.text == "(":
            depth += 1
            if depth == 1:
                continue
        elif t.kind == OP and t.text == ")":
            depth -= 1
            if depth == 0:
                break
        if depth == 1 and t.kind == OP and t.text == ",":
            args.append([])
        else:
            args[-1].append(t)
    return args


def _decode(toks: Sequence[Token]) -> list[Hit]:
    hits: list[Hit] = []
    for i in _call_indices(toks, "decode"):
        args = _split_args(toks, i + 1)
        searches = range(1, len(args) - 1, 2)  # even positions that have a result after them
        has_null = any(len(args[k]) == 1 and _is(args[k][0], IDENT, "null") for k in searches)
        message = "Oracle DECODE() call with a NULL search argument" if has_null else None
        hits.append((toks[i], message))
    return hits


def _idents(*names: str) -> TokenCheck:
    wanted = set(names)

    def check(toks: Sequence[Token]) -> list[Hit]:
        return [(t, None) for t in toks if t.kind == IDENT and t.text in wanted]

    return check


def _sequence_pseudo_columns(toks: Sequence[Token]) -> list[Hit]:
    hits: list[Hit] = []
    for i, t in enumerate(toks):
        if t.kind != IDENT or t.text not in ("nextval", "currval"):
            continue
        before, name = _at(toks, i - 1), _at(toks, i - 2)
        if not _is(before, OP, ".") or name is None or name.kind != IDENT:
            continue
        parts = [name.text]
        k = i - 3
        while _is(_at(toks, k), OP, ".") and (p := _at(toks, k - 1)) and p.kind == IDENT:
            parts.insert(0, p.text)
            k -= 2
        hits.append((t, ".".join(parts)))
    return hits


def _rownum(toks: Sequence[Token]) -> list[Hit]:
    return [
        (t, None)
        for i, t in enumerate(toks)
        if _is(t, IDENT, "rownum") and not _is(_at(toks, i - 1), OP, ".")
    ]


def _connect_by(toks: Sequence[Token]) -> list[Hit]:
    return [
        (t, None)
        for i, t in enumerate(toks)
        if _is(t, IDENT, "connect") and _is(_at(toks, i + 1), IDENT, "by")
    ]


def _outer_join(toks: Sequence[Token]) -> list[Hit]:
    return [
        (t, None)
        for i, t in enumerate(toks)
        if _is(t, OP, "(") and _is(_at(toks, i + 1), OP, "+") and _is(_at(toks, i + 2), OP, ")")
    ]


def _autonomous(toks: Sequence[Token]) -> list[Hit]:
    return [
        (t, None)
        for i, t in enumerate(toks)
        if _is(t, IDENT, "pragma") and _is(_at(toks, i + 1), IDENT, "autonomous_transaction")
    ]


def _dbms_output(toks: Sequence[Token]) -> list[Hit]:
    hits: list[Hit] = []
    for i, t in enumerate(toks):
        if not _is(t, IDENT, "dbms_output"):
            continue
        member, after = _at(toks, i + 2), _at(toks, i + 3)
        if not (_is(_at(toks, i + 1), OP, ".") and member and member.kind == IDENT):
            continue
        if not (_is(after, OP, "(") or _is(after, OP, ";")):
            continue
        start = i
        if _is(_at(toks, i - 1), OP, "."):
            if not _is(_at(toks, i - 2), IDENT, "sys") or _is(_at(toks, i - 3), OP, "."):
                continue
            start = i - 2
        hits.append((toks[start], None))
    return hits


def _from_dual(toks: Sequence[Token]) -> list[Hit]:
    return [
        (t, None)
        for i, t in enumerate(toks)
        if _is(t, IDENT, "dual") and _is(_at(toks, i - 1), IDENT, "from")
    ]


def _empty_string(toks: Sequence[Token]) -> list[Hit]:
    return [(t, None) for t in toks if t.kind == STRING and t.text.lower() in ("''", "n''")]


class _Spec:
    """Contract entry: severity, title and the text of the findings of one rule."""

    def __init__(
        self,
        severity: str,
        title: str,
        check: TokenCheck,
        message: str,
        rationale: str,
        fix_hint: str,
    ) -> None:
        self.severity, self.title, self.check = severity, title, check
        self.message, self.rationale, self.fix_hint = message, rationale, fix_hint


_SPECS: dict[str, _Spec] = {
    "MIG001": _Spec(
        "low",
        "NVL call",
        _call_of("nvl"),
        "Oracle NVL() call",
        "PostgreSQL has no NVL(); the portable function is COALESCE.",
        "COALESCE(a, b)",
    ),
    "MIG002": _Spec(
        "low",
        "DECODE call",
        _decode,
        "Oracle DECODE() call",
        "PostgreSQL has no DECODE(); it is a CASE expression. DECODE also treats NULL as equal "
        "to NULL, which CASE x WHEN NULL never does.",
        "CASE expr WHEN s1 THEN r1 ... ELSE default END; use CASE WHEN expr IS NULL ... for a "
        "NULL search value",
    ),
    "MIG003": _Spec(
        "medium",
        "SYSDATE / SYSTIMESTAMP",
        _idents("sysdate", "systimestamp"),
        "Oracle SYSDATE/SYSTIMESTAMP",
        "In Oracle SYSDATE is a DATE and `sysdate - d` is a number of days; in PostgreSQL the "
        "same subtraction gives an interval and `+ 1` is an error.",
        "CURRENT_TIMESTAMP, LOCALTIMESTAMP or CURRENT_DATE, depending on the type needed; "
        "review the date arithmetic around it",
    ),
    "MIG004": _Spec(
        "low",
        "Sequence NEXTVAL / CURRVAL",
        _sequence_pseudo_columns,
        "Oracle sequence pseudo-column",
        "PostgreSQL has no sequence pseudo-columns; sequences are used through the functions "
        "nextval() and currval().",
        "nextval('seq') / currval('seq')",
    ),
    "MIG005": _Spec(
        "medium",
        "ROWNUM",
        _rownum,
        "Oracle ROWNUM pseudo-column",
        "PostgreSQL has no ROWNUM; Oracle assigns it before ORDER BY, so it is not a row limit "
        "or a numbering you can port one to one.",
        "LIMIT n to cap rows, or row_number() OVER (ORDER BY ...) to number them",
    ),
    "MIG006": _Spec(
        "medium",
        "CONNECT BY",
        _connect_by,
        "Oracle hierarchical query (CONNECT BY)",
        "PostgreSQL has no CONNECT BY, START WITH, PRIOR or LEVEL.",
        "WITH RECURSIVE ... (recursive common table expression)",
    ),
    "MIG007": _Spec(
        "medium",
        "Outer-join operator (+)",
        _outer_join,
        "Oracle outer-join operator (+)",
        "PostgreSQL does not support the (+) operator; outer joins use ANSI syntax.",
        "LEFT JOIN / RIGHT JOIN ... ON ... (the table marked (+) is the optional side)",
    ),
    "MIG008": _Spec(
        "high",
        "PRAGMA AUTONOMOUS_TRANSACTION",
        _autonomous,
        "PRAGMA AUTONOMOUS_TRANSACTION",
        "PostgreSQL routines cannot commit independently of the caller's transaction; there is "
        "no equivalent pragma.",
        "run the work on a separate connection (dblink, pg_background or the application) or "
        "redesign it so it does not need an independent commit",
    ),
    "MIG009": _Spec(
        "low",
        "DBMS_OUTPUT call",
        _dbms_output,
        "Oracle DBMS_OUTPUT call",
        "PostgreSQL has no DBMS_OUTPUT package; PL/pgSQL reports messages with RAISE.",
        "RAISE NOTICE '...'",
    ),
    "MIG010": _Spec(
        "low",
        "FROM DUAL",
        _from_dual,
        "Oracle FROM DUAL",
        "PostgreSQL has no DUAL table; a SELECT without a FROM clause returns one row.",
        "omit the FROM clause",
    ),
    "MIG011": _Spec(
        "high",
        "Empty string literal",
        _empty_string,
        "Empty string literal '' (NULL in Oracle)",
        "In Oracle '' is NULL; in PostgreSQL it is an empty string that is not NULL, so "
        "comparisons, concatenations and IS NULL tests silently behave differently.",
        "write NULL where NULL is meant; if an empty string is meant, test for it explicitly "
        "(x IS NULL OR x = '')",
    ),
}


def _finding(rid: str, tok: Token, path: str, detail: str | None) -> Finding:
    """``detail`` is a rule-specific text: the full message (MIG002) or the sequence (MIG004)."""
    spec = _SPECS[rid]
    message, fix = spec.message, spec.fix_hint
    if rid == "MIG002" and detail:
        message = detail
    elif rid == "MIG003":
        message = f"Oracle {tok.text.upper()}"
    elif rid == "MIG004" and detail:
        message = f"Oracle sequence pseudo-column {detail}.{tok.text.upper()}"
        fix = f"{tok.text}('{detail}')"
    return Finding(
        rid, spec.severity, Location(path, tok.line, tok.col), message, spec.rationale, fix
    )


def _unit_spans(ir: FileIR) -> list[tuple[int, int, str]]:
    spans: list[tuple[int, int, str]] = []

    def sub(sp: Subprogram, prefix: str) -> None:
        name = f"{prefix}.{sp.name}"
        if sp.end_line:
            spans.append((sp.line, sp.end_line, name))
        for n in sp.nested:
            sub(n, name)

    def unit(u: Unit) -> None:
        spans.append((u.line, u.end_line or ir.lines, u.name))
        for sp in u.subprograms:
            sub(sp, u.name)

    for u in ir.units:
        unit(u)
    return spans


def _with_unit(findings: list[Finding], ir: FileIR) -> list[Finding]:
    spans = _unit_spans(ir)
    out = []
    for f in findings:
        inside = [s for s in spans if s[0] <= f.location.line <= s[1]]
        unit = min(inside, key=lambda s: (s[1] - s[0], -s[0]))[2] if inside else None
        out.append(replace(f, unit=unit))
    return out


def _check(rid: str, toks: Sequence[Token], path: str) -> list[Finding]:
    return [_finding(rid, tok, path, detail) for tok, detail in _SPECS[rid].check(toks)]


def _rule_check(rid: str) -> Callable[[FileIR], list[Finding]]:
    def check(ir: FileIR) -> list[Finding]:
        # A Rule works from the IR, which has no source text: re-read the file it names.
        src = Path(ir.path).read_text(encoding="utf-8", errors="replace")
        return _check(rid, tokenize(src), ir.path)

    return check


MIGRATION_RULES: dict[str, Rule] = {
    rid: Rule(rid, spec.severity, spec.title, _rule_check(rid)) for rid, spec in _SPECS.items()
}


def migrate_source(src: str, path: str, rules: Iterable[str] | None = None) -> list[Finding]:
    """Findings of the selected migration rules (default: all) in ``src``, sorted by location.

    Inline ``-- plsql-lens: disable=MIGnnn`` directives are honored.
    """
    selected = sorted(MIGRATION_RULES) if rules is None else list(rules)
    unknown = [r for r in selected if r not in MIGRATION_RULES]
    if unknown:
        raise ValueError(f"unknown migration rule(s): {', '.join(unknown)}")
    toks = tokenize(src)
    findings = [f for rid in selected for f in _check(rid, toks, path)]
    findings.sort(key=lambda f: (f.location.line, f.location.col, f.rule_id))
    ir = parse_source(src, path)
    return apply_suppressions(ir, _with_unit(findings, ir))


def migrate_file(path: str | Path, rules: Iterable[str] | None = None) -> list[Finding]:
    """Read ``path`` (UTF-8, undecodable bytes replaced) and run :func:`migrate_source`."""
    return migrate_source(
        Path(path).read_text(encoding="utf-8", errors="replace"), str(path), rules
    )
