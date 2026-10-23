"""Prompt construction for utPLSQL test generation and repair."""

from __future__ import annotations

import re
from pathlib import Path

from ..parser import FileIR, Subprogram, Unit, parse_file
from .targets import Target

_INSTRUCTIONS = """\
You write utPLSQL v3.1 unit tests for Oracle 23ai PL/SQL.

Write ONE test package named {test_package} (package specification and package body) that tests the
unit `{unit}` shown below. Rules:
- Annotate the specification: `--%suite(...)`, one `--%test(...)` per test procedure, and
  `--%throws(-20001)` style annotations for expected errors. Use `--%beforeeach` / `--%aftereach`
  only if they help; every test must be independent. utPLSQL rolls back DML after each test.
- Use `ut.expect(actual).to_equal(expected)`, `.to_be_null()`, `.to_be_true()`, `.to_be_empty()`,
  `.to_be_greater_than(...)` etc. Never use COMMIT. Do not use DBMS_OUTPUT assertions.
- Cover normal cases, boundaries, NULL inputs and every error branch visible in the source.
- The package under test is in the same schema: call it unqualified (`{call_example}`).
- Use only objects shown in the context below. When expected values depend on table data, create the
  rows you need inside the test, or compute the expected value with an independent SQL query at run
  time; never hard-code values you cannot see.
- Rows you insert must satisfy NOT NULL, CHECK and FOREIGN KEY constraints shown in the DDL: reuse
  existing parent rows (select one, e.g. an existing job_id or department_id) instead of
  inventing keys.
- Compare BOOLEAN with `.to_be_true()` / `.to_be_false()`; for a REF CURSOR, fetch it into a local
  variable and compare the values.
- Answer with a single ```sql code block containing the package specification, a line with `/`,
  the package body, and a final line with `/`. No prose outside the block.
"""

_REPAIR = """\
The test package below failed to compile in Oracle. Fix it and return the COMPLETE corrected
package (specification, `/`, body, `/`) in a single ```sql block, without prose. Keep the test
intent; change only what the errors require.

Oracle errors:
{error}

Current test package:
```sql
{code}
```

--- Context (the unit under test) ---
{context}
"""


def _unit_source(target: Target, root: Path) -> tuple[str, str]:
    """(source text of the unit's body/bodies, package specification text or '')."""
    wanted = target.unit.lower().split(".")
    name = wanted[-1]
    pkg = wanted[0] if len(wanted) == 2 else None
    bodies: list[str] = []
    spec_text = ""
    for rel in target.source_files:
        path = root / rel
        text = path.read_text(encoding="utf-8", errors="replace")
        lines = text.splitlines()
        ir: FileIR = parse_file(path)
        for u in ir.units:
            if pkg and u.name == pkg and u.kind == "package":
                spec_text += text
            for sp in _candidates(u, pkg, name):
                if sp.has_body and sp.end_line:
                    bodies.append("\n".join(lines[sp.line - 1 : sp.end_line]))
            if (
                pkg is None
                and u.name == name
                and u.kind in ("procedure", "function")
                and u.end_line
            ):
                bodies.append("\n".join(lines[u.line - 1 : u.end_line]))
    if not bodies:
        raise LookupError(f"{target.id}: no body found for {target.unit}")
    return "\n\n".join(bodies), spec_text


def _candidates(u: Unit, pkg: str | None, name: str) -> list[Subprogram]:
    if pkg is None or u.name != pkg:
        return []
    return [sp for sp in u.subprograms if sp.name == name]


def _tables(ddl_text: str) -> dict[str, str]:
    """``create table`` statements by lower-case table name."""
    out: dict[str, str] = {}
    for m in re.finditer(r"(?is)\bcreate\s+table\s+([A-Za-z_][\w$#]*)\b.*?;", ddl_text):
        out[m.group(1).lower()] = m.group(0)
    return out


def _alter_statements(ddl_text: str) -> dict[str, list[str]]:
    """``alter table`` statements (constraints) by lower-case table name."""
    out: dict[str, list[str]] = {}
    for m in re.finditer(r"(?is)\balter\s+table\s+([A-Za-z_][\w$#]*)\b.*?;", ddl_text):
        out.setdefault(m.group(1).lower(), []).append(m.group(0).strip())
    return out


def _ddl_context(target: Target, root: Path, body_text: str) -> str:
    """DDL of the tables the unit mentions, their constraints, and the tables they reference."""
    words = set(re.findall(r"[A-Za-z_][\w$#]*", body_text.lower()))
    tables: dict[str, str] = {}
    alters: dict[str, list[str]] = {}
    for rel in target.ddl_files:
        text = Path(root / rel).read_text(errors="replace")
        tables.update(_tables(text))
        for name, stmts in _alter_statements(text).items():
            alters.setdefault(name, []).extend(stmts)
    chosen = [n for n in tables if n in words]
    parts: list[str] = []
    seen: set[str] = set()

    def add(name: str) -> None:
        if name in seen or name not in tables:
            return
        seen.add(name)
        parts.append(tables[name].strip())
        parts.extend(alters.get(name, []))

    for name in chosen:
        add(name)
    for name in list(seen):  # one level of referenced parent tables
        for stmt in [tables[name], *alters.get(name, [])]:
            for ref in re.findall(r"(?i)\breferences\s+([A-Za-z_][\w$#]*)", stmt):
                add(ref.lower())
    return "\n\n".join(parts)


def build_context(target: Target, root: Path) -> str:
    body, spec = _unit_source(target, root)
    ddl = _ddl_context(target, root, body)
    sections = []
    if spec:
        sections.append(f"Package specification:\n```sql\n{spec.strip()}\n```")
    sections.append(f"Source of `{target.unit}` (all overloads):\n```sql\n{body}\n```")
    if ddl:
        sections.append(f"Tables touched by the unit (DDL):\n```sql\n{ddl}\n```")
    return "\n\n".join(sections)


def build_generation_prompt(target: Target, root: Path) -> str:
    call = target.unit if "." in target.unit else target.unit
    head = _INSTRUCTIONS.format(
        test_package=target.test_package, unit=target.unit, call_example=call
    )
    return f"{head}\n--- Context ---\n{build_context(target, root)}\n"


def build_repair_prompt(target: Target, root: Path, code: str, error: str) -> str:
    return _REPAIR.format(
        error=error.strip()[:4000], code=code, context=build_context(target, root)
    )
