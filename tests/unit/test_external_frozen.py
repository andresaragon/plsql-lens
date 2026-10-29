"""The reference rules of the external-split evaluation (F4b) are frozen."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_engine_files_match_the_frozen_hashes() -> None:
    frozen = json.loads((ROOT / "docs" / "benchmarks" / "external" / "frozen.json").read_text())
    current = {
        str(f.relative_to(ROOT)): hashlib.sha256(f.read_bytes()).hexdigest()
        for f in sorted(
            [
                *(ROOT / "src/plsql_lens/parser").glob("*.py"),
                *(ROOT / "src/plsql_lens/rules").glob("*.py"),
                ROOT / "docs/rules.md",
            ]  # fmt: skip
        )
    }
    assert current == frozen["files"], "engine or contract changed after the freeze"
    canon = json.dumps(current, sort_keys=True, separators=(",", ":"))
    assert hashlib.sha256(canon.encode()).hexdigest() == frozen["engine_sha256"]
