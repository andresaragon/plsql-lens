"""Scorer and statistics for the benchmark (written before the implementation)."""

from __future__ import annotations

import pytest

from plsql_lens.bench.model import Found, Manifest, Region
from plsql_lens.bench.score import score
from plsql_lens.bench.stats import prf, wilson


def test_wilson_known_values() -> None:
    lo, hi = wilson(5, 10)
    assert lo == pytest.approx(0.2366, abs=1e-3) and hi == pytest.approx(0.7634, abs=1e-3)
    lo, hi = wilson(10, 10)
    assert lo == pytest.approx(0.7225, abs=1e-3) and hi == 1.0
    assert wilson(0, 10)[0] == 0.0
    assert wilson(0, 0) == (0.0, 1.0)  # no information


def test_prf_counts_and_intervals() -> None:
    m = prf(tp=8, fp=2, fn=4)
    assert m["precision"] == pytest.approx(0.8) and m["recall"] == pytest.approx(8 / 12)
    assert m["f1"] == pytest.approx(2 * 8 / (2 * 8 + 2 + 4))
    assert m["precision_ci"][0] < 0.8 < m["precision_ci"][1]
    assert m["recall_ci"][0] < 8 / 12 < m["recall_ci"][1]
    assert prf(0, 0, 0)["precision"] is None and prf(0, 0, 0)["f1"] is None


def manifest() -> Manifest:
    return Manifest(
        split="dev",
        seed=1,
        files={"s.pkb": "standalone", "i.pkb": "injected"},
        regions=[
            Region("s.pkb", "PLL003", "defect", 10, 14, (12,)),
            Region("s.pkb", "PLL003", "negative", 20, 24, ()),
            Region("s.pkb", "PLL007", "defect", 30, 40, (31, 35, 39)),
            Region("i.pkb", "PLL001", "defect", 100, 108, (104,)),
            Region("i.pkb", "PLL001", "negative", 120, 128, ()),
        ],
    )


def counts(res, rule):  # type: ignore[no-untyped-def]
    c = res.per_rule[rule]
    return (c.tp, c.fp, c.fn)


def test_tp_fp_fn_definition() -> None:
    found = [
        Found("s.pkb", "PLL003", 12),  # on the marked line -> TP
        Found("s.pkb", "PLL003", 22),  # inside a hard negative -> FP
        Found("s.pkb", "PLL007", 31),  # one of three expected occurrences
        Found("s.pkb", "PLL007", 33),  # inside the defect region but not on an expected line -> FP
        Found("i.pkb", "PLL001", 104),  # TP
    ]
    res = score(manifest(), found)
    assert counts(res, "PLL003") == (1, 1, 0)
    assert counts(res, "PLL007") == (1, 1, 2)  # 2 expected occurrences missed
    assert counts(res, "PLL001") == (1, 0, 0)
    assert counts(res, "PLL002") == (0, 0, 0)


def test_unmatched_expected_line_is_fn() -> None:
    res = score(manifest(), [])
    assert counts(res, "PLL003") == (0, 0, 1)
    assert counts(res, "PLL007") == (0, 0, 3)
    assert counts(res, "PLL001") == (0, 0, 1)


def test_duplicate_findings_on_one_line_count_once() -> None:
    res = score(manifest(), [Found("s.pkb", "PLL003", 12), Found("s.pkb", "PLL003", 12)])
    assert counts(res, "PLL003") == (1, 0, 0)


def test_other_rules_inside_a_region_are_ignored_not_fp() -> None:
    # PLL007 fires inside a PLL003 negative: the region only labels PLL003.
    res = score(manifest(), [Found("s.pkb", "PLL007", 22), Found("s.pkb", "PLL001", 12)])
    assert res.per_rule["PLL007"].fp == 0 and res.per_rule["PLL001"].fp == 0
    assert res.cross == 2


def test_outside_regions_standalone_is_fp_injected_is_background() -> None:
    res = score(manifest(), [Found("s.pkb", "PLL002", 3), Found("i.pkb", "PLL002", 3)])
    assert counts(res, "PLL002") == (0, 1, 0)
    assert res.background == 1


def test_total_aggregates_rules() -> None:
    res = score(manifest(), [Found("s.pkb", "PLL003", 12), Found("s.pkb", "PLL003", 22)])
    t = res.total
    assert (t.tp, t.fp, t.fn) == (1, 1, 4 + 3 - 3 + 0)  # PLL007(3)+PLL001(1) missed
