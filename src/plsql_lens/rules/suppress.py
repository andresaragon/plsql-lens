"""Inline suppression: ``-- plsql-lens: disable=PLL007`` (see docs/rules.md)."""

from __future__ import annotations

from ..parser import FileIR, Subprogram, Unit
from .model import Finding


def _scopes(ir: FileIR) -> dict[int, int]:
    """Header line -> last line, for every unit and subprogram that has a body."""
    out: dict[int, int] = {}

    def sub(sp: Subprogram) -> None:
        if sp.end_line:
            out[sp.line] = max(out.get(sp.line, 0), sp.end_line)
        for n in sp.nested:
            sub(n)

    def unit(u: Unit) -> None:
        if u.end_line:
            out[u.line] = max(out.get(u.line, 0), u.end_line)
        for sp in u.subprograms:
            sub(sp)

    for u in ir.units:
        unit(u)
    return out


def apply_suppressions(ir: FileIR, findings: list[Finding]) -> list[Finding]:
    if not ir.suppressions:
        return findings
    scopes = _scopes(ir)
    spans: list[tuple[int, int, frozenset[str]]] = []
    for line, ids in ir.suppressions:
        spans.append((line, scopes.get(line, line), ids))  # block scope on a header line
    return [
        f
        for f in findings
        if not any(lo <= f.location.line <= hi and f.rule_id in ids for lo, hi, ids in spans)
    ]
