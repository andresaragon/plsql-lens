"""Converter and evaluator for the external split (written before the implementation).

Synthetic data only: the real cases in docs/benchmarks/external/cases are not touched by these tests.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest

from plsql_lens.bench.external import (
    apply_adjudication,
    convert,
    evaluate,
    manifest_hash,
    render_tables,
)
from plsql_lens.bench.model import Found

SYN = Path(__file__).resolve().parents[1] / "fixtures" / "external_synthetic"


def conv(tmp_path: Path):  # type: ignore[no-untyped-def]
    return convert(SYN, tmp_path / "out")


def test_convert_strips_markers_and_header_but_keeps_line_numbers(tmp_path: Path) -> None:
    m = conv(tmp_path)
    src = (SYN / "s001.pkb").read_text().splitlines()
    clean = (tmp_path / "out" / "s001.pkb").read_text().splitlines()
    assert len(clean) == len(src)
    text = "\n".join(clean)
    assert not re.search(r"\b(expect|beyond|clean)\b|author:|domain:|difficulty:|note:", text)
    assert clean[9].strip() == "commit;"  # marker comment removed from the code line
    assert "execute immediate 'x' || i;" in text
    assert m.cases[0].file == "s001.pkb"


def test_convert_records_expect_clean_and_beyond(tmp_path: Path) -> None:
    c = conv(tmp_path).cases[0]
    assert c.expect == {"PLL003": [10], "PLL002": [26], "PLL007": [26]}
    assert c.beyond == {"PLL003": [24]}
    (clean,) = c.clean["PLL003"]
    assert (clean["line"], clean["start"], clean["end"]) == (18, 13, 19)  # enclosing p2


def test_convert_is_deterministic_and_hashed(tmp_path: Path) -> None:
    a = convert(SYN, tmp_path / "a")
    b = convert(SYN, tmp_path / "b")
    assert manifest_hash(a) == manifest_hash(b)
    assert (tmp_path / "a" / "manifest.json").read_bytes() == (
        tmp_path / "b" / "manifest.json"
    ).read_bytes()
    assert set(json.loads((tmp_path / "a" / "manifest.json").read_text())["sha256"]) == {"s001.pkb"}


def test_strict_scoring(tmp_path: Path) -> None:
    m = conv(tmp_path)
    found = [
        Found("s001.pkb", "PLL003", 10),  # TP
        Found("s001.pkb", "PLL003", 18),  # inside the clean subprogram -> FP (in clean)
        Found("s001.pkb", "PLL003", 24),  # beyond line: a real-world hit, not an FP
        Found("s001.pkb", "PLL002", 9),  # unmarked line -> FP
        Found("s001.pkb", "PLL002", 9),  # duplicate
    ]
    s = evaluate(m, found)
    p3, p2, p7 = s.per_rule["PLL003"], s.per_rule["PLL002"], s.per_rule["PLL007"]
    assert (p3["tp"], p3["fp"], p3["fn"], p3["fp_in_clean"]) == (1, 1, 0, 1)
    assert (p2["tp"], p2["fp"], p2["fn"]) == (0, 1, 1)
    assert (p7["tp"], p7["fp"], p7["fn"]) == (0, 0, 1)
    assert s.beyond["PLL003"] == {"hit": 1, "total": 1}
    assert [(u["rule"], u["line"]) for u in s.unmarked] == [("PLL002", 9), ("PLL003", 18)]
    assert [(u["rule"], u["line"]) for u in s.missed] == [("PLL002", 26), ("PLL007", 26)]


def test_adjudication_moves_findings_but_never_touches_the_strict_table(tmp_path: Path) -> None:
    m = conv(tmp_path)
    s = evaluate(m, [Found("s001.pkb", "PLL003", 10), Found("s001.pkb", "PLL002", 9)])
    strict_before = json.dumps(s.per_rule, sort_keys=True)
    decisions = [
        {"file": "s001.pkb", "rule": "PLL002", "line": 9, "kind": "unmarked_finding",
         "verdict": "real_defect", "reason": "author missed it"},
        {"file": "s001.pkb", "rule": "PLL007", "line": 26, "kind": "missed_expect",
         "verdict": "marker_wrong", "reason": "only twice"},
    ]  # fmt: skip
    adj = apply_adjudication(s, decisions)
    assert json.dumps(s.per_rule, sort_keys=True) == strict_before
    assert (adj["PLL002"]["tp"], adj["PLL002"]["fp"], adj["PLL002"]["fn"]) == (1, 0, 1)
    assert (adj["PLL007"]["tp"], adj["PLL007"]["fp"], adj["PLL007"]["fn"]) == (0, 0, 0)


def test_unlisted_unmarked_findings_stay_false_positives_in_the_adjudicated_table(
    tmp_path: Path,
) -> None:
    m = conv(tmp_path)
    s = evaluate(m, [Found("s001.pkb", "PLL002", 9)])
    assert apply_adjudication(s, [])["PLL002"]["fp"] == 1


def test_tables_are_labeled(tmp_path: Path) -> None:
    m = conv(tmp_path)
    s = evaluate(m, [Found("s001.pkb", "PLL003", 10)])
    md = render_tables("Rules (frozen)", s, apply_adjudication(s, []), provisional=True)
    assert "Strict" in md and "Adjudicated" in md
    assert "provisional" in md.lower() and "pending your review" in md.lower()
    assert "0.95" not in "".join(md.split())  # no invented numbers
    assert (
        render_tables("x", s, apply_adjudication(s, []), provisional=False)
        .lower()
        .count("provisional")
        == 0
    )
    pytest.importorskip("json")


# ---- orchestration on a throw-away root (synthetic cases, real engine) --------------------------


def make_root(tmp_path: Path) -> Path:
    import hashlib
    import shutil

    root = tmp_path / "root"
    (root / "docs/benchmarks/external/cases").mkdir(parents=True)
    shutil.copy(SYN / "s001.pkb", root / "docs/benchmarks/external/cases/s001.pkb")
    (root / "docs/rules.md").write_text("contract")
    frozen = {
        "frozen_at_commit": "abc",
        "files": {"docs/rules.md": hashlib.sha256(b"contract").hexdigest()},
    }
    (root / "docs/benchmarks/external/frozen.json").write_text(json.dumps(frozen))
    (root / "docs/benchmarks/seal.json").write_text("{}")
    return root


def test_convert_seal_run_once_and_report(tmp_path: Path) -> None:
    from plsql_lens.bench.external_run import ExternalError, do_convert, do_report, do_run

    root = make_root(tmp_path)
    with pytest.raises(ExternalError):  # nothing sealed yet
        do_convert(root)
    digest = do_convert(root, seal=True)
    assert json.loads((root / "docs/benchmarks/seal.json").read_text())["external"] == digest
    assert do_convert(root) == digest
    res = do_run(root)
    assert res["frozen_at_commit"] == "abc" and res["findings"]
    with pytest.raises(ExternalError, match="once"):
        do_run(root)
    text = do_report(root)
    assert "Strict" in text and "Rules (frozen)" in text
    assert (root / "docs/benchmarks/external/results.md").read_text() == text


def test_run_refuses_when_the_engine_is_not_the_frozen_one(tmp_path: Path) -> None:
    from plsql_lens.bench.external_run import ExternalError, do_convert, do_run

    root = make_root(tmp_path)
    do_convert(root, seal=True)
    (root / "docs/rules.md").write_text("changed contract")
    with pytest.raises(ExternalError, match="frozen"):
        do_run(root)


def test_llm_baseline_is_recorded_and_scored(tmp_path: Path) -> None:
    from plsql_lens.bench.external_run import do_convert, do_llm, do_report, do_run
    from plsql_lens.bench.llm_baseline import build_prompt
    from plsql_lens.llm import FakeProvider, LLMResponse

    root = make_root(tmp_path)
    do_convert(root, seal=True)
    do_run(root)
    text = (root / "docs/benchmarks/external/data/s001.pkb").read_text()
    # build_prompt needs the contract table; give the throw-away root one
    (root / "docs/rules.md").write_text("| Rule | x |\n|---|---|\n\n## Suppression\n")
    import hashlib

    frozen = json.loads((root / "docs/benchmarks/external/frozen.json").read_text())
    frozen["files"]["docs/rules.md"] = hashlib.sha256(
        (root / "docs/rules.md").read_bytes()
    ).hexdigest()
    (root / "docs/benchmarks/external/frozen.json").write_text(json.dumps(frozen))
    prompt = build_prompt(root, "s001.pkb", text)
    rec = do_llm(
        root,
        FakeProvider({prompt: LLMResponse('[{"rule":"PLL003","line":10}]', 5, 2, 0.01, "m")}),
        "m",
        2.0,
    )
    assert rec["responses"]["s001.pkb"]["cost_usd"] == 0.01
    assert "LLM only" in do_report(root)
