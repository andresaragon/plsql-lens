"""Seeded, deterministic benchmark generation (written before the implementation)."""

from __future__ import annotations

import json
from pathlib import Path

from plsql_lens.bench.generate import generate, manifest_hash
from plsql_lens.bench.score import score

TEMPLATE = {
    "rule": "PLL003",
    "split": "dev",
    "defects": [
        {
            "id": "d1",
            "note": "commit in loop",
            "code": (
                "procedure @@proc@@ is\n  @@var@@ number;\nbegin\n  for i in 1 .. 3 loop\n"
                "    @@var@@ := i;\n    commit; -- @expect\n  end loop;\nend @@proc@@;"
            ),
        }
    ],
    "negatives": [
        {
            "id": "n1",
            "note": "commit after loop",
            "code": (
                "procedure @@proc@@ is\nbegin\n  for i in 1 .. 3 loop\n    null;\n  end loop;\n"
                "  commit;\nend @@proc@@;"
            ),
        }
    ],
}
BASE = (
    "create or replace package body base_pkg as\n"
    "  procedure existing is\n  begin\n    null;\n  end existing;\n"
    "end base_pkg;\n/\n"
)


def setup(tmp_path: Path) -> tuple[Path, Path]:
    tdir = tmp_path / "tpl"
    tdir.mkdir(exist_ok=True)
    (tdir / "PLL003.json").write_text(json.dumps(TEMPLATE))
    base = tmp_path / "base.pkb"
    base.write_text(BASE)
    return tdir, base


def gen(tmp_path: Path, out: str, seed: int = 7):  # type: ignore[no-untyped-def]
    tdir, base = setup(tmp_path)
    return generate(
        "dev", seed, tmp_path / out, templates_dir=tdir, base_files=[base],
        defects_per_rule=4, negatives_per_rule=4, snippets_per_file=2,
    )  # fmt: skip


def test_generation_is_deterministic_byte_for_byte(tmp_path: Path) -> None:
    m1 = gen(tmp_path, "a")
    m2 = gen(tmp_path, "b")
    assert manifest_hash(m1) == manifest_hash(m2)
    for p in sorted((tmp_path / "a").rglob("*")):
        if p.is_file():
            q = tmp_path / "b" / p.relative_to(tmp_path / "a")
            assert p.read_bytes() == q.read_bytes()


def test_seed_changes_the_output(tmp_path: Path) -> None:
    assert manifest_hash(gen(tmp_path, "a", 7)) != manifest_hash(gen(tmp_path, "b", 8))


def test_counts_markers_and_placeholders(tmp_path: Path) -> None:
    m = gen(tmp_path, "a")
    defects = [r for r in m.regions if r.kind == "defect"]
    negatives = [r for r in m.regions if r.kind == "negative"]
    assert len(defects) == 4 and len(negatives) == 4
    for r in defects:
        text = (tmp_path / "a" / r.file).read_text().splitlines()
        assert r.start <= r.expected[0] <= r.end
        assert "commit" in text[r.expected[0] - 1].lower()
        assert "@expect" not in "\n".join(text)  # markers never reach the generated source
    assert "@@" not in "".join(p.read_text() for p in (tmp_path / "a").rglob("*.pkb"))


def test_both_item_kinds_and_injection_keeps_the_original_text(tmp_path: Path) -> None:
    m = gen(tmp_path, "a")
    kinds = set(m.files.values())
    assert kinds == {"standalone", "injected"}
    injected = next(p for p, k in m.files.items() if k == "injected")
    body = (tmp_path / "a" / injected).read_text()
    assert "procedure existing is" in body and body.rstrip().endswith("/")
    assert body.index("existing") < body.index("commit")  # snippets go before the closing END


def test_perfect_findings_score_perfectly(tmp_path: Path) -> None:
    from plsql_lens.bench.model import Found

    m = gen(tmp_path, "a")
    found = [Found(r.file, r.rule, line) for r in m.regions for line in r.expected]
    res = score(m, found)
    assert (res.total.tp, res.total.fp, res.total.fn) == (4, 0, 0)


def test_pll007_templates_get_unique_incidental_literals() -> None:
    import random

    from plsql_lens.bench.generate import _uniquify_literals

    raw = (
        "procedure p(v varchar2(30)) is\nbegin\n  if x = 2 then y := 'unknown'; end if; -- 2 'unknown'\n"
        "  if x = 2 then y := 'unknown'; end if;\n  z := 0 + 1 + @@num@@ + 20001; w := ' ' || '' || '@@str@@';\n"
        "end;"
    )
    out = _uniquify_literals(raw, random.Random(1), set())
    assert (
        out.count("@@num@@") == 1 and "@@str@@" in out and "20001" in out and "varchar2(30)" in out
    )
    assert "-- 2 'unknown'" in out  # comments untouched
    assert " 2 " not in out.replace(
        "-- 2", ""
    )  # the incidental 2 is gone, both occurrences renamed alike
    import re

    nums = re.findall(r"x = (\d+)", out)
    assert len(nums) == 2 and nums[0] == nums[1] and nums[0] != "2"
    strs = re.findall(r"y := '(unknown_\d+)'", out)
    assert len(strs) == 2 and strs[0] == strs[1]
