from __future__ import annotations

import json
import subprocess
from pathlib import Path

import pytest

from plsql_lens.bench.config import BEFORE_SHA, base_files, heldout_files, repo_root
from plsql_lens.bench.extras import corpus_delta, corpus_files, heldout_manifest
from plsql_lens.bench.llm_baseline import (
    build_prompt,
    findings_from_recording,
    parse_findings,
    rules_contract,
    select_sample,
)
from plsql_lens.bench.model import Found, Manifest, Region
from plsql_lens.bench.report import render_results
from plsql_lens.bench.run import SealError, item_counts, run_llm_scoring, run_split
from plsql_lens.bench.score import score

ROOT = repo_root()


def _have_before_sha() -> bool:
    r = subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", f"{BEFORE_SHA}^{{commit}}"],
                       capture_output=True)  # fmt: skip
    return r.returncode == 0


needs_git = pytest.mark.skipif(not _have_before_sha(), reason="full git history not available")


def test_base_files_are_disjoint_between_splits_and_exclude_the_reserve() -> None:
    dev, test = base_files(ROOT, "dev"), base_files(ROOT, "test")
    assert dev and test and not set(dev) & set(test)
    held = heldout_files(ROOT)
    assert not {p.relative_to(ROOT).as_posix() for p in dev + test} & held


def test_parse_findings_accepts_fenced_and_plain_json_and_ignores_garbage() -> None:
    assert parse_findings('```json\n[{"rule":"pll001","line":4}]\n```', "f") == [
        Found("f", "PLL001", 4)
    ]
    assert parse_findings('text [{"rule": "PLL002", "line": 9}, {"x": 1}] more', "f") == [
        Found("f", "PLL002", 9)
    ]
    assert parse_findings("no findings", "f") == []
    assert parse_findings("[not json]", "f") == []


def test_prompt_numbers_lines_and_carries_the_contract() -> None:
    p = build_prompt(ROOT, "a.pkb", "x\ny")
    assert "    1 x" in p and "    2 y" in p and "PLL007" in p and "Suppression" not in p
    assert rules_contract(ROOT).startswith("| Rule |")


def test_select_sample_is_seeded_and_balanced() -> None:
    files = {f"s{i}.pkb": "standalone" for i in range(10)} | {
        f"i{i}.pkb": "injected" for i in range(10)
    }
    m = Manifest("test", 1, files, [])
    a, b = select_sample(m, 8, 5), select_sample(m, 8, 5)
    assert a == b and len(a) == 8 and sum(f.startswith("s") for f in a) == 4
    assert select_sample(m, 8, 6) != a


def test_recording_roundtrip_to_findings() -> None:
    rec = {"responses": {"a": {"text": '[{"rule":"PLL003","line":2}]'}, "b": {"error": "boom"}}}
    assert findings_from_recording(rec) == [Found("a", "PLL003", 2)]


def test_corpus_delta_and_heldout_manifest() -> None:
    d = corpus_delta([Found("f", "PLL001", 1), Found("f", "PLL002", 2)], [Found("f", "PLL002", 2),
                     Found("g", "PLL003", 3)])  # fmt: skip
    assert d["removed"] == [["f", "PLL001", 1]] and d["added"] == [["g", "PLL003", 3]]
    assert d["before_counts"]["PLL001"] == 1 and d["after_counts"]["PLL003"] == 1
    assert len(corpus_files(ROOT)) > 200
    h = heldout_manifest(ROOT)
    perfect = [Found(r.file, r.rule, line) for r in h.regions for line in r.expected]
    assert score(h, perfect).total.fp == 0 and score(h, perfect).total.fn == 0


def test_render_results_with_synthetic_raw(tmp_path: Path) -> None:
    from plsql_lens.bench.score import Score

    sc = Score()
    sc.per_rule["PLL001"].tp = 3
    split = {
        "split": "test", "seed": 1, "manifest_sha256": "ab", "before_sha": "cd",
        "items": {"files": 2, "standalone": 1, "injected": 1,
                  "per_rule": {"PLL001": {"defect_regions": 3, "defect_spans": 3, "negatives": 2}}},
        "before": sc.to_dict(), "after": sc.to_dict(),
    }  # fmt: skip
    raw = tmp_path / "raw"
    raw.mkdir()
    (raw / "test.json").write_text(json.dumps(split))
    (raw / "actionable.json").write_text(
        json.dumps(
            {
                "note": "n",
                "per_rule": {
                    "PLL001": {
                        "sampled": 4,
                        "actionable": 3,
                        "contract_holds": 4,
                        "total_findings": 9,
                    }
                },
            }
        )
    )
    md = render_results(tmp_path)
    assert "## Held-out `test` split" in md and "PLL001" in md and "Actionable rate" in md
    assert render_results(tmp_path) == md  # deterministic


def test_item_counts() -> None:
    m = Manifest("d", 1, {"a": "standalone", "b": "injected"},
                 [Region("a", "PLL007", "defect", 1, 9, (2, 4, 6)), Region("b", "PLL007", "negative", 1, 5)])  # fmt: skip
    c = item_counts(m)
    assert c["per_rule"]["PLL007"] == {"defect_regions": 1, "defect_spans": 3, "negatives": 1}


def test_llm_scoring_needs_recordings(tmp_path: Path) -> None:
    assert run_llm_scoring(tmp_path) is None


@needs_git
def test_run_split_is_deterministic_and_enforces_the_seal(tmp_path: Path) -> None:
    a = run_split(ROOT, tmp_path / "a", "dev")
    b = run_split(ROOT, tmp_path / "b", "dev")
    assert a["manifest_sha256"] == b["manifest_sha256"]
    assert a["after"] == b["after"] and a["items"]["files"] > 50
    (tmp_path / "c").mkdir()
    (tmp_path / "c" / "seal.json").write_text(json.dumps({"dev": "0" * 64}))
    with pytest.raises(SealError):
        run_split(ROOT, tmp_path / "c", "dev")
