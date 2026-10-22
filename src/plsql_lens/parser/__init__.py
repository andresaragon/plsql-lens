"""Parser: PL/SQL source -> IR."""

from __future__ import annotations

from pathlib import Path

from .ir import Call, FileIR, Param, ParseIssue, Stmt, Subprogram, Unit
from .structure import parse_source


def parse_file(path: str | Path) -> FileIR:
    """Parse one PL/SQL file; never raises on syntax problems (see ``FileIR.issues``)."""
    p = Path(path)
    return parse_source(p.read_text(encoding="utf-8", errors="replace"), str(path))


__all__ = [
    "Call",
    "FileIR",
    "Param",
    "ParseIssue",
    "Stmt",
    "Subprogram",
    "Unit",
    "parse_file",
    "parse_source",
]
