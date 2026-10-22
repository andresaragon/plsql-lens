"""Phase F1 acceptance tests (SPEC section 3, F1).

Written before the implementation. Targets are taken verbatim from the SPEC and
must not be adjusted to make the tests pass:

* >= 95 % of corpus files parse without fatal error (partial IR allowed)
* inventory F1 >= 0.95 for units and >= 0.90 for call edges on the labeled set
* Mermaid output renders (structurally valid, within Mermaid's default edge cap)
"""

from __future__ import annotations

import json
import re
from pathlib import Path

import pytest
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.inventory import build_inventory

ROOT = Path(__file__).resolve().parents[2]
CORPUS = ROOT / "corpus"
GROUND_TRUTH = sorted((ROOT / "tests" / "acceptance" / "ground_truth").glob("*.json"))

PARSE_RATE_TARGET = 0.95
UNITS_F1_TARGET = 0.95
EDGES_F1_TARGET = 0.90
MERMAID_MAX_EDGES = 500  # Mermaid's default maxEdges


def f1(predicted: set[object], expected: set[object]) -> float:
    if not predicted and not expected:
        return 1.0
    tp = len(predicted & expected)
    if tp == 0:
        return 0.0
    precision, recall = tp / len(predicted), tp / len(expected)
    return 2 * precision * recall / (precision + recall)


def test_ground_truth_exists() -> None:
    assert GROUND_TRUTH, "no hand-labeled ground truth found"


def test_corpus_parse_rate() -> None:
    inv = build_inventory([CORPUS])
    files = inv.files
    assert len(files) >= 100
    ok = sum(1 for f in files if f.ok)
    rate = ok / len(files)
    failed = [f.path for f in files if not f.ok][:10]
    assert rate >= PARSE_RATE_TARGET, f"parse rate {rate:.3f}; failing: {failed}"


@pytest.mark.parametrize("gt_path", GROUND_TRUTH, ids=lambda p: p.stem)
def test_units_and_edges_f1(gt_path: Path) -> None:
    gt = json.loads(gt_path.read_text())
    inv = build_inventory([ROOT / f for f in gt["files"]])
    units_f1 = f1({u.key for u in inv.units}, set(gt["units"]))
    edges_f1 = f1({(e.caller, e.callee) for e in inv.edges}, {tuple(e) for e in gt["edges"]})
    assert units_f1 >= UNITS_F1_TARGET, f"units F1 {units_f1:.3f}"
    assert edges_f1 >= EDGES_F1_TARGET, f"edges F1 {edges_f1:.3f}"


def test_cli_json_and_mermaid(tmp_path: Path) -> None:
    runner = CliRunner()
    out_json = tmp_path / "inventory.json"
    res = runner.invoke(app, ["inventory", str(CORPUS), "--format", "json", "-o", str(out_json)])
    assert res.exit_code == 0, res.output
    data = json.loads(out_json.read_text())
    assert {"files", "units", "edges"} <= data.keys()
    assert data["units"] and data["edges"]

    out_md = tmp_path / "callgraph.mmd"
    res = runner.invoke(app, ["inventory", str(CORPUS), "--format", "mermaid", "-o", str(out_md)])
    assert res.exit_code == 0, res.output
    lines = out_md.read_text().splitlines()
    assert lines[0].startswith("flowchart")
    edge_lines = [ln for ln in lines if "-->" in ln]
    assert 0 < len(edge_lines) <= MERMAID_MAX_EDGES
    node = r'[A-Za-z_]\w*(\["[^"\n]*"\])?'
    for ln in edge_lines:
        assert re.fullmatch(rf"\s*{node}\s*-->(\|[^|\n]*\|)?\s*{node}\s*", ln), ln


def test_cli_stdout_default() -> None:
    res = CliRunner().invoke(app, ["inventory", str(CORPUS / "logger"), "--format", "json"])
    assert res.exit_code == 0, res.output
    assert json.loads(res.output)["units"]
