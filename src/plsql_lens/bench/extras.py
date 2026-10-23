"""Real-corpus deltas and the F2 held-out reserve, scored with the same definitions."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from ..inventory import collect_files
from .config import heldout_files
from .model import RULE_IDS, Found, Manifest, Region


def corpus_files(root: Path) -> list[str]:
    """Corpus files minus the held-out reserve (the same 259-file set used in the F2 report)."""
    held = heldout_files(root)
    rels = (p.relative_to(root).as_posix() for p in collect_files([root / "corpus"]))
    return sorted(r for r in rels if r not in held)


def corpus_delta(before: list[Found], after: list[Found]) -> dict[str, object]:
    b, a = {(f.file, f.rule, f.line) for f in before}, {(f.file, f.rule, f.line) for f in after}
    cb, ca = Counter(f.rule for f in before), Counter(f.rule for f in after)  # raw, as in F2
    return {
        "before_counts": {r: cb[r] for r in RULE_IDS},
        "after_counts": {r: ca[r] for r in RULE_IDS},
        "removed": [list(x) for x in sorted(b - a)],
        "added": [list(x) for x in sorted(a - b)],
    }


def heldout_manifest(root: Path) -> Manifest:
    labels = json.loads((root / "tests" / "heldout" / "labels.json").read_text())
    regions = [
        Region(f, e["rule"], "defect", e["line"], e["line"], (e["line"],))
        for f, items in sorted(labels.items())
        for e in items
    ]
    return Manifest("heldout", 0, {f: "standalone" for f in labels}, regions)
