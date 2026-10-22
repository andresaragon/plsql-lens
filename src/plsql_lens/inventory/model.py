"""Inventory: IR files -> units, parameters and a resolved call graph."""

from __future__ import annotations

from collections import defaultdict
from collections.abc import Iterable, Sequence
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from ..parser import FileIR, Param, Subprogram, Unit, parse_file
from ..parser.ir import Call

CODE_SUFFIXES = frozenset(
    [
        ".pks",
        ".pkb",
        ".tps",
        ".tpb",
        ".trg",
        ".plb",
        ".sql",
        ".prc",
        ".fnc",
        ".pck",
        ".pls",
        ".pkg",
        ".typ",
        ".tbp",
        ".tsp",
    ]
)


@dataclass(frozen=True, slots=True)
class FileReport:
    path: str
    lines: int
    ok: bool
    issues: tuple[str, ...] = ()


@dataclass(frozen=True, slots=True)
class InventoryUnit:
    key: str  # "kind:qualified_name", lowercase
    kind: str  # package | procedure | function | trigger | type
    name: str
    container: str | None  # owning package/type for subprograms
    files: tuple[str, ...]
    line: int
    params: tuple[Param, ...] = ()
    return_type: str | None = None
    has_body: bool = False


@dataclass(frozen=True, slots=True)
class Edge:
    caller: str
    callee: str
    count: int = 1


@dataclass(frozen=True, slots=True)
class Inventory:
    files: tuple[FileReport, ...]
    units: tuple[InventoryUnit, ...]
    edges: tuple[Edge, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "files": [
                {"path": f.path, "lines": f.lines, "ok": f.ok, "issues": list(f.issues)}
                for f in self.files
            ],
            "units": [
                {
                    "key": u.key,
                    "kind": u.kind,
                    "name": u.name,
                    "container": u.container,
                    "files": list(u.files),
                    "line": u.line,
                    "params": [
                        {"name": p.name, "mode": p.mode, "type": p.type, "default": p.has_default}
                        for p in u.params
                    ],
                    "return_type": u.return_type,
                    "has_body": u.has_body,
                }
                for u in self.units
            ],
            "edges": [
                {"caller": e.caller, "callee": e.callee, "count": e.count} for e in self.edges
            ],
        }


def collect_files(paths: Iterable[str | Path]) -> list[Path]:
    out: list[Path] = []
    for p in map(Path, paths):
        if p.is_dir():
            out.extend(q for q in p.rglob("*") if q.is_file() and q.suffix.lower() in CODE_SUFFIXES)
        else:
            out.append(p)
    return sorted(set(out))


@dataclass
class _Acc:
    kind: str
    name: str
    container: str | None
    spec_rank: int  # 0 = declared in a spec, 1 = body only
    line: int
    files: list[str] = field(default_factory=list)
    params: tuple[Param, ...] = ()
    return_type: str | None = None
    has_body: bool = False
    order: int = 0


def _all_calls(sp: Subprogram | Unit, shadow: frozenset[str]) -> list[Call]:
    """Calls of a subprogram, including nested ones, minus calls to local names."""
    local = shadow | sp.locals
    out = [c for c in sp.calls if not (len(c.chain) == 1 and c.chain[0] in local)]
    for n in sp.nested if isinstance(sp, Subprogram) else sp.subprograms:
        out.extend(_all_calls(n, local))
    return out


def build_inventory_from_irs(irs: Sequence[FileIR]) -> Inventory:
    accs: dict[str, _Acc] = {}
    callers: list[tuple[str, str | None, list[Call]]] = []  # (caller key, container, calls)
    order = 0

    def register(
        kind: str,
        name: str,
        container: str | None,
        spec: bool,
        line: int,
        path: str,
        params: tuple[Param, ...],
        rtype: str | None,
        body: bool,
    ) -> str:
        nonlocal order
        qn = f"{container}.{name}" if container else name
        a = accs.get(qn)
        rank = 0 if spec else 1
        if a is None:
            order += 1
            a = accs[qn] = _Acc(kind, name, container, rank, line, order=order)
            a.params, a.return_type = params, rtype
        elif (rank, order) < (a.spec_rank, a.order) or (rank == 0 and a.spec_rank == 1):
            a.kind, a.spec_rank, a.line, a.params, a.return_type = kind, rank, line, params, rtype
        if path not in a.files:
            a.files.append(path)
        a.has_body = a.has_body or body
        return f"{accs[qn].kind}:{qn}"

    for ir in irs:
        for u in ir.units:
            if u.kind in ("package", "package_body", "type", "type_body"):
                base = "package" if u.kind.startswith("package") else "type"
                is_spec = u.kind in ("package", "type")
                register(base, u.name, None, is_spec, u.line, ir.path, (), None, not is_spec)
                for sp in u.subprograms:
                    is_decl_only = not sp.has_body
                    register(
                        sp.kind,
                        sp.name,
                        u.name,
                        is_spec or is_decl_only,
                        sp.line,
                        ir.path,
                        sp.params,
                        sp.return_type,
                        sp.has_body,
                    )
                    if sp.has_body:
                        callers.append(
                            (f"{sp.kind}:{u.name}.{sp.name}", u.name, _all_calls(sp, frozenset()))
                        )
                if u.calls:
                    callers.append((f"{base}:{u.name}", u.name, list(u.calls)))
            else:
                register(
                    u.kind, u.name, None, False, u.line, ir.path, u.params, u.return_type, True
                )
                callers.append((f"{u.kind}:{u.name}", None, _all_calls(u, frozenset())))

    # Callers were recorded with the kind at registration time; remap to the final kind.
    def final_key(raw: str) -> str:
        qn = raw.split(":", 1)[1]
        return f"{accs[qn].kind}:{qn}" if qn in accs else raw

    edges: dict[tuple[str, str], int] = defaultdict(int)
    for caller, container, calls in callers:
        ck = final_key(caller)
        for c in calls:
            target = _resolve(c.chain, container, accs)
            if target is not None and (c.followed_by != "other" or accs[target].kind == "function"):
                edges[(ck, f"{accs[target].kind}:{target}")] += 1

    units = tuple(
        InventoryUnit(
            f"{a.kind}:{qn}",
            a.kind,
            a.name,
            a.container,
            tuple(a.files),
            a.line,
            a.params,
            a.return_type,
            a.has_body,
        )
        for qn, a in sorted(accs.items(), key=lambda kv: kv[1].order)
    )
    files = tuple(
        FileReport(ir.path, ir.lines, ir.ok, tuple(f"{i.line}: {i.message}" for i in ir.issues))
        for ir in irs
    )
    return Inventory(files, units, tuple(Edge(a, b, n) for (a, b), n in sorted(edges.items())))


def _resolve(chain: tuple[str, ...], container: str | None, accs: dict[str, _Acc]) -> str | None:
    if len(chain) == 1:
        if container and f"{container}.{chain[0]}" in accs:
            return f"{container}.{chain[0]}"
        a = accs.get(chain[0])
        return (
            chain[0]
            if a is not None and a.container is None and a.kind in ("procedure", "function")
            else None
        )
    qn = f"{chain[-2]}.{chain[-1]}"
    return qn if qn in accs and accs[qn].container is not None else None


def build_inventory(paths: Iterable[str | Path]) -> Inventory:
    """Parse every PL/SQL file under ``paths`` and build the inventory and call graph."""
    base = Path.cwd()
    irs = []
    for f in collect_files(paths):
        ir = parse_file(f)
        try:
            rel = str(f.resolve().relative_to(base))
        except ValueError:
            rel = str(f)
        irs.append(FileIR(rel, ir.lines, ir.units, ir.issues, ir.suppressions))
    return build_inventory_from_irs(irs)
