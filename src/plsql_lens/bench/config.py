"""Fixed benchmark configuration. Changing any of this changes the sealed hashes."""

from __future__ import annotations

import json
from pathlib import Path

# The "before" rules: src/plsql_lens/ as of origin/main at the start of F4 (end of F2 + F3, untouched).
BEFORE_SHA = "ca4ba438b3f0086a1a603b4726bbb45d346dd60f"
SEEDS = {"dev": 1001, "test": 2002}
MAX_BASE_LINES = 400
LLM_SAMPLE_FILES = 40
LLM_SAMPLE_SEED = 3003


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def heldout_files(root: Path) -> set[str]:
    p = root / "tests" / "heldout" / "labels.json"
    return set(json.loads(p.read_text())) if p.exists() else set()


def base_files(root: Path, split: str) -> list[Path]:
    """Corpus package bodies injected into, disjoint between splits (even/odd index of the sorted list)."""
    eligible: list[Path] = []
    held = heldout_files(root)
    for p in sorted((root / "corpus").rglob("*.pkb")):
        rel = p.relative_to(root).as_posix()
        text = p.read_text(encoding="utf-8", errors="replace")
        if rel in held or "package body" not in text.lower():
            continue
        if text.count("\n") + 1 > MAX_BASE_LINES:
            continue
        eligible.append(p)
    return eligible[0::2] if split == "dev" else eligible[1::2]
