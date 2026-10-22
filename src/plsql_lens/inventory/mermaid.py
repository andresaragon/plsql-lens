"""Mermaid rendering of the call graph."""

from __future__ import annotations

from collections import defaultdict

from .model import Inventory


def _owner(key: str) -> str:
    """Package/type (or standalone unit) that owns a unit key."""
    qn = key.split(":", 1)[1]
    return qn.split(".", 1)[0]


def render_mermaid(inv: Inventory, level: str = "package") -> str:
    """Render ``flowchart LR``; ``level`` is ``package`` (aggregated) or ``unit``."""
    if level == "unit":
        pairs = {(e.caller.split(":", 1)[1], e.callee.split(":", 1)[1]): e.count for e in inv.edges}
        names = {u.key.split(":", 1)[1] for u in inv.units if u.kind != "package"}
    else:
        agg: dict[tuple[str, str], int] = defaultdict(int)
        for e in inv.edges:
            a, b = _owner(e.caller), _owner(e.callee)
            if a != b:
                agg[(a, b)] += e.count
        pairs = dict(agg)
        names = {_owner(u.key) for u in inv.units}
    ids = {n: f"n{i}" for i, n in enumerate(sorted(names | {x for p in pairs for x in p}))}
    lines = ["flowchart LR"]
    linked = {x for p in pairs for x in p}
    for (a, b), cnt in sorted(pairs.items()):
        label = f"|{cnt}|" if level == "package" and cnt > 1 else ""
        lines.append(f'  {ids[a]}["{a}"] -->{label} {ids[b]}["{b}"]')
    for solo in sorted(names - linked):
        lines.append(f'  {ids[solo]}["{solo}"]')
    return "\n".join(lines) + "\n"
