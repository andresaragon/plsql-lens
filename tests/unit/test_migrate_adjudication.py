"""F5c: the adjudicated findings are exactly the ones a fresh run over corpus/ selects."""

from __future__ import annotations

import json
import random
from pathlib import Path

from plsql_lens.inventory import collect_files
from plsql_lens.migrate import MIGRATION_RULES, migrate_file

ROOT = Path(__file__).resolve().parents[2]
DOC = json.loads((ROOT / "docs" / "reports" / "phase-5" / "adjudication.json").read_text())
SEED, SAMPLE = 20261030, 20
FULL = ("MIG002", "MIG003", "MIG004", "MIG005", "MIG006", "MIG007", "MIG010", "MIG011")
SAMPLED = ("MIG001", "MIG008", "MIG009")
IMPACTS = {"mechanical", "needs-rewrite", "semantic-trap", "benign"}


def _fresh() -> dict[str, list[tuple[str, int, int]]]:
    by_rule: dict[str, list[tuple[str, int, int]]] = {r: [] for r in MIGRATION_RULES}
    for path in collect_files([ROOT / "corpus"]):
        for f in migrate_file(path):
            rel = Path(f.location.path).resolve().relative_to(ROOT).as_posix()
            by_rule[f.rule_id].append((rel, f.location.line, f.location.col))
    return {r: sorted(v) for r, v in by_rule.items()}


def _expected() -> dict[str, list[tuple[str, int, int]]]:
    fresh = _fresh()
    out: dict[str, list[tuple[str, int, int]]] = {}
    for rule in (*FULL, *SAMPLED):
        pop = fresh[rule]
        out[rule] = pop if rule in FULL else sorted(random.Random(SEED).sample(pop, SAMPLE))
    return out


def test_the_adjudicated_items_are_exactly_the_selected_findings() -> None:
    adjudicated: dict[str, list[tuple[str, int, int]]] = {}
    for it in DOC["items"]:
        adjudicated.setdefault(it["rule"], []).append((it["file"], it["line"], it["col"]))
    expected = _expected()
    assert sorted(adjudicated) == sorted(expected)
    for rule, items in expected.items():
        assert sorted(adjudicated[rule]) == items, rule


def test_strata_report_the_population_and_how_it_was_chosen() -> None:
    fresh = _fresh()
    for rule, s in DOC["strata"].items():
        assert s["population"] == len(fresh[rule]), rule
        assert s["adjudicated"] == (s["population"] if rule in FULL else SAMPLE), rule
        assert s["adjudicated"] == sum(i["rule"] == rule for i in DOC["items"]), rule


def test_every_item_has_a_verdict_an_impact_and_a_note() -> None:
    for it in DOC["items"]:
        assert it["verdict"] in {"tp", "fp"}
        assert it["impact"] in IMPACTS
        assert it["note"].strip()
