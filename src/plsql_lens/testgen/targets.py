"""Test-generation targets: the manifest and unit resolution."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from ..inventory import InventoryUnit, build_inventory


@dataclass(frozen=True, slots=True)
class Target:
    id: str
    unit: str  # "pkg.proc" or standalone "proc", case-insensitive
    source_files: tuple[str, ...]  # repo-relative; package spec and body, or the file with the unit
    difficulty: str  # easy | medium | hard
    reason: str  # why this unit was chosen
    ddl_files: tuple[str, ...] = ()  # DDL scanned for the tables the unit touches
    install: tuple[str, ...] = ()  # setup scripts this unit depends on (documentation + checks)

    @property
    def test_package(self) -> str:
        return f"test_{self.id}"


@dataclass(frozen=True, slots=True)
class Manifest:
    setup: tuple[str, ...]
    targets: tuple[Target, ...]


def load_manifest_full(path: Path) -> Manifest:
    data = json.loads(path.read_text())
    targets = tuple(
        Target(
            id=t["id"],
            unit=t["unit"],
            source_files=tuple(t["source_files"]),
            difficulty=t["difficulty"],
            reason=t["reason"],
            ddl_files=tuple(t.get("ddl_files", ())),
            install=tuple(t.get("install", ())),
        )
        for t in data["targets"]
    )
    return Manifest(tuple(data.get("setup", ())), targets)


def load_manifest(path: Path) -> list[Target]:
    return list(load_manifest_full(path).targets)


def resolve_unit(target: Target, root: Path) -> InventoryUnit:
    """Find the target's unit in the inventory of its source files."""
    inv = build_inventory([root / f for f in target.source_files])
    wanted = target.unit.lower()
    for u in inv.units:
        if u.key.split(":", 1)[1] == wanted and u.kind in ("procedure", "function"):
            return u
    raise LookupError(f"{target.id}: unit {target.unit} not found in {target.source_files}")
