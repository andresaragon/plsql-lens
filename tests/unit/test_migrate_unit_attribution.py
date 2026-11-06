"""The ``unit`` of a migrate finding and the routines of the inventory (F5-G6, issue #4).

Diagnosis in ``docs/reports/migrate-unit-attribution.md``. Root cause: in ``parse_block_body``
(``src/plsql_lens/parser/structure.py``, frozen) an ``END`` that closes a CASE *expression* and is
followed by ``LOOP`` (``FOR i IN 1 .. CASE ... END LOOP``) is read as ``END LOOP``; the block never
closes and every routine after it is swallowed. The two ``xfail`` tests are the minimal reproducers
and fail until the parser is changed (the parser is sealed by ``test_external_frozen.py``).

The module also holds the text scan that the report uses as an independent reference (it uses
neither the parser nor ``_unit_spans``). Run it as a script:

    uv run python tests/unit/test_migrate_unit_attribution.py PATH [PATH ...]
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pytest

from plsql_lens.migrate import migrate_source
from plsql_lens.parser import Subprogram, parse_source

XFAIL = pytest.mark.xfail(
    strict=True,
    reason="needs a parser change; parser is frozen, see docs/reports/migrate-unit-attribution.md",
)

# A source written for this repo. `first_fn` has a CASE expression that ends right before LOOP.
MINIMAL = """\
CREATE OR REPLACE PACKAGE BODY pkg_min AS

  FUNCTION first_fn(p IN BOOLEAN) RETURN NUMBER IS
    n NUMBER := 0;
  BEGIN
    FOR i IN 1 .. CASE WHEN p THEN 8 ELSE 7 END
    LOOP
      n := n + i;
    END LOOP;
    RETURN n;
  END first_fn;

  FUNCTION second_fn RETURN DATE IS
  BEGIN
    RETURN SYSDATE;
  END second_fn;

END pkg_min;
/
"""
SECOND_FN_LINE = 15  # the line of SYSDATE


def routine_names(src: str) -> list[str]:
    ir = parse_source(src, "min.pkb")
    return [sp.name for u in ir.units for sp in u.subprograms]


# --- the reproducers (they fail until the parser is changed) -----------------------------------


@XFAIL
def test_the_inventory_lists_the_routine_after_a_case_expression_that_ends_before_loop() -> None:
    assert routine_names(MINIMAL) == ["first_fn", "second_fn"]


@XFAIL
def test_a_finding_in_the_routine_after_it_gets_that_routine_as_its_unit() -> None:
    (f,) = migrate_source(MINIMAL, "min.pkb", ["MIG003"])
    assert f.location.line == SECOND_FN_LINE
    assert f.unit == "pkg_min.second_fn"


# --- what holds today (controls: they pass, and they say what the defect is not) --------------


def test_the_same_source_with_parentheses_around_the_case_expression_is_read_correctly() -> None:
    src = MINIMAL.replace(
        "CASE WHEN p THEN 8 ELSE 7 END\n    LOOP", "(CASE WHEN p THEN 8 ELSE 7 END) LOOP"
    )
    assert routine_names(src) == ["first_fn", "second_fn"]


def test_findings_keep_their_number_location_and_severity_whatever_the_unit_says() -> None:
    (f,) = migrate_source(MINIMAL, "min.pkb", ["MIG003"])
    assert (f.location.line, f.severity) == (SECOND_FN_LINE, "medium")
    assert f.unit is not None  # informative only: some unit is always reported, here a wrong one


# --- the independent text scan -----------------------------------------------------------------

HEADER = re.compile(
    r"^\s*(?:create\s+(?:or\s+replace\s+)?(?:editionable\s+|noneditionable\s+)?)?"
    r"(?:(?:member|static|constructor|overriding|final|instantiable|map|order)\s+)*"
    r"(function|procedure)\s+\"?([A-Za-z_][\w$#]*)\"?",
    re.IGNORECASE,
)
Header = tuple[int, int, str]  # line, indentation, lowercase name


def blank_comments_and_strings(src: str) -> str:
    """Spaces in place of comments and string contents; line breaks and columns are kept."""

    def keep_breaks(s: str) -> str:
        return "".join(ch if ch == "\n" else " " for ch in s)

    out: list[str] = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("--", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
        elif src.startswith("/*", i):
            j = src.find("*/", i + 2)
            j = n if j < 0 else j + 2
            out.append(keep_breaks(src[i:j]))
        elif (
            c in "qQ"
            and src[i + 1 : i + 2] == "'"
            and i + 2 < n
            and not (i > 0 and (src[i - 1].isalnum() or src[i - 1] in "_$#"))
        ):  # q'[ ... ]' quoting
            closer = {"[": "]", "(": ")", "{": "}", "<": ">"}.get(src[i + 2], src[i + 2])
            j = src.find(closer + "'", i + 3)
            j = n if j < 0 else j + 2
            out.append(keep_breaks(src[i:j]))
        elif c == "'":
            j = i + 1
            while j < n and not (src[j] == "'" and src[j + 1 : j + 2] != "'"):
                j += 2 if src[j] == "'" else 1
            j = min(j + 1, n)
            out.append("'" + keep_breaks(src[i + 1 : j - 1]) + "'")
        else:
            j = i + 1
            out.append(c)
        i = j
    return "".join(out)


def routine_headers(src: str) -> list[Header]:
    """Headers of routines *with a body*: the declaration reaches IS/AS before a semicolon."""
    lines = blank_comments_and_strings(src).splitlines()
    found: list[Header] = []
    for n, line in enumerate(lines, 1):
        m = HEADER.match(line)
        if not m:
            continue
        rest = "\n".join(lines[n - 1 : n + 59])[m.end() :]
        depth, ends_with = 0, None
        for tok in re.finditer(r"[();]|\b(?:is|as)\b", rest, re.IGNORECASE):
            t = tok.group().lower()
            if t in "()":
                depth += 1 if t == "(" else -1
            elif depth == 0:
                ends_with = t
                break
        if ends_with in ("is", "as"):
            found.append((n, len(line) - len(line.lstrip()), m.group(2).lower()))
    return found


def containing_chain(headers: list[Header], line: int) -> list[str]:
    """Names that may contain ``line``: the last header before it, then the earlier headers of
    strictly smaller indentation. No ``END`` is read, so the text scan cannot see where a routine
    stops (a trigger, a view or a package initialization block after it look like part of it)."""
    chain: list[str] = []
    indent: int | None = None
    for _, ind, name in reversed([h for h in headers if h[0] <= line]):
        if indent is None or ind < indent:
            chain.append(name)
            indent = ind
    return chain


def test_the_text_scan_finds_both_routines_of_the_minimal_source() -> None:
    headers = routine_headers(MINIMAL)
    assert [h[2] for h in headers] == ["first_fn", "second_fn"]
    assert containing_chain(headers, SECOND_FN_LINE) == ["second_fn"]
    assert containing_chain(headers, 8) == ["first_fn"]
    assert containing_chain(headers, 1) == []


def test_the_text_scan_skips_declarations_comments_strings_and_q_quotes() -> None:
    src = (
        "CREATE PACKAGE p AS\n"
        "  FUNCTION decl RETURN NUMBER;\n"  # a declaration, no body
        "END p;\n"
        "-- FUNCTION in_comment RETURN NUMBER IS\n"
        "x := 'FUNCTION in_string RETURN NUMBER IS';\n"
        "y := q'[\n  FUNCTION in_q RETURN NUMBER IS\n]';\n"
        "  PROCEDURE real_one(a NUMBER) IS\n"
    )
    assert [h[2] for h in routine_headers(src)] == ["real_one"]


# --- script: the comparison of the report -------------------------------------------------------


def subprogram_names(sp: Subprogram) -> set[str]:
    names = {sp.name.lower()}
    for nested in sp.nested:
        names |= subprogram_names(nested)
    return names


def compare(root: Path, paths: list[Path]) -> dict[str, object]:
    from plsql_lens.migrate import migrate_file
    from plsql_lens.parser import parse_file

    total = {"findings": 0, "match_last_header": 0, "match_enclosing": 0, "outside_routine": 0}
    mismatches: list[tuple[str, int, str, str | None, str]] = []
    missing: dict[str, list[str]] = {}
    headers_total = 0
    for path in paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        headers = routine_headers(text)
        headers_total += len(headers)
        ir = parse_file(path)
        known = {u.name.lower() for u in ir.units}
        for u in ir.units:
            for sp in u.subprograms:
                known |= subprogram_names(sp)
        gone = sorted({h[2] for h in headers} - known)
        if gone:
            missing[str(path.relative_to(root))] = gone
        for f in migrate_file(path):
            total["findings"] += 1
            chain = containing_chain(headers, f.location.line)
            leaf = f.unit.split(".")[-1].lower() if f.unit else None
            if not chain:
                total["outside_routine"] += 1
            elif leaf == chain[0]:
                total["match_last_header"] += 1
            elif leaf in chain:
                total["match_enclosing"] += 1
            else:
                rel = str(path.relative_to(root))
                mismatches.append((rel, f.location.line, f.rule_id, f.unit, chain[0]))
    return {"total": total, "mismatches": mismatches, "missing": missing, "headers": headers_total}


def main(argv: list[str]) -> int:
    from plsql_lens.inventory import collect_files

    root = Path.cwd()
    paths = sorted(collect_files([Path(a) for a in argv]))
    r = compare(root.resolve(), [p.resolve() for p in paths])
    print("findings:", r["total"])
    print("routines with a body (text scan):", r["headers"])
    gone = r["missing"]
    assert isinstance(gone, dict)
    print(
        "routines the parser does not list:",
        sum(len(v) for v in gone.values()),
        "in",
        len(gone),
        "files",
    )
    for file, names in gone.items():
        print("  ", file, names)
    mism = r["mismatches"]
    assert isinstance(mism, list)
    print(
        "units that disagree with the text scan:",
        len(mism),
        "in",
        len({m[0] for m in mism}),
        "files",
    )
    for m in mism:
        print("  ", m)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
