"""The `test` split is frozen: regenerating it must reproduce the sealed manifest hash."""

from __future__ import annotations

import json
from pathlib import Path

from plsql_lens.bench.config import SEEDS, base_files, repo_root
from plsql_lens.bench.generate import generate, manifest_hash

ROOT = repo_root()


def test_test_split_matches_its_seal(tmp_path: Path) -> None:
    sealed = json.loads((ROOT / "docs" / "benchmarks" / "seal.json").read_text())["test"]
    m = generate(
        "test", SEEDS["test"], tmp_path, base_files=base_files(ROOT, "test"), base_root=ROOT
    )
    assert manifest_hash(m) == sealed


def test_committed_test_files_match_their_recorded_hashes() -> None:
    import hashlib

    data = ROOT / "docs" / "benchmarks" / "data" / "test"
    manifest = json.loads((data / "manifest.json").read_text())
    for rel, digest in manifest["sha256"].items():
        assert hashlib.sha256((data / rel).read_bytes()).hexdigest() == digest, rel
