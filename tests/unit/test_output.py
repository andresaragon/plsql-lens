from __future__ import annotations

import json
from pathlib import Path

from typer.testing import CliRunner

from plsql_lens import __version__, parse_file
from plsql_lens.cli import app
from plsql_lens.rules import RULES, review
from plsql_lens.rules.output import to_json, to_sarif, to_table

FIX = Path(__file__).resolve().parents[1] / "fixtures" / "rules"


def findings():  # type: ignore[no-untyped-def]
    out = []
    for rule in ("PLL001", "PLL003", "PLL007"):
        out += review(parse_file(FIX / rule / "pos_1.pkb"), rules=[rule])
    return out


def test_table_has_header_and_one_row_per_finding() -> None:
    fs = findings()
    lines = to_table(fs).splitlines()
    assert lines[0].split()[:3] == ["SEVERITY", "RULE", "LOCATION"]
    assert len(lines) == 2 + len(fs)
    assert str(fs[0].location) in to_table(fs)
    assert to_table([]).strip() == "No findings."


def test_json_roundtrip_fields() -> None:
    data = json.loads(to_json(findings()))
    assert data["version"] == __version__
    f = data["findings"][0]
    assert set(f) >= {
        "rule_id",
        "severity",
        "file",
        "line",
        "col",
        "message",
        "rationale",
        "fix_hint",
    }


def _check_sarif_structure(doc: dict) -> None:  # type: ignore[type-arg]
    """Structural validation against the SARIF 2.1.0 required properties (no network)."""
    assert doc["version"] == "2.1.0"
    assert doc["$schema"].endswith("sarif-2.1.0.json")
    (run,) = doc["runs"]
    driver = run["tool"]["driver"]
    assert driver["name"] == "plsql-lens" and driver["version"]
    rule_ids = [r["id"] for r in driver["rules"]]
    assert rule_ids == sorted(RULES)
    for r in driver["rules"]:
        assert r["shortDescription"]["text"]
        assert r["defaultConfiguration"]["level"] in {"error", "warning", "note", "none"}
    for res in run["results"]:
        assert res["ruleId"] in rule_ids
        assert driver["rules"][res["ruleIndex"]]["id"] == res["ruleId"]
        assert res["level"] in {"error", "warning", "note", "none"}
        assert res["message"]["text"]
        (loc,) = res["locations"]
        phys = loc["physicalLocation"]
        assert "\\" not in phys["artifactLocation"]["uri"]
        assert phys["region"]["startLine"] >= 1 and phys["region"]["startColumn"] >= 1


def test_sarif_is_structurally_valid() -> None:
    doc = json.loads(to_sarif(findings()))
    _check_sarif_structure(doc)
    assert doc["runs"][0]["results"]
    levels = {r["ruleId"]: r["level"] for r in doc["runs"][0]["results"]}
    assert levels["PLL001"] == "error" and levels["PLL003"] == "warning"
    assert levels["PLL007"] == "note"


def test_sarif_empty_run_is_valid() -> None:
    _check_sarif_structure(json.loads(to_sarif([])))


def test_cli_review_formats(tmp_path: Path) -> None:
    runner = CliRunner()
    target = str(FIX / "PLL003" / "pos_1.pkb")
    res = runner.invoke(app, ["review", target])
    assert res.exit_code == 0 and "PLL003" in res.output
    res = runner.invoke(app, ["review", target, "--format", "json"])
    assert json.loads(res.output)["findings"]
    out = tmp_path / "r.sarif"
    res = runner.invoke(app, ["review", target, "--format", "sarif", "-o", str(out)])
    assert res.exit_code == 0
    _check_sarif_structure(json.loads(out.read_text()))


def test_cli_review_directory_and_rule_filter() -> None:
    res = CliRunner().invoke(
        app, ["review", str(FIX / "PLL001"), "--format", "json", "--rules", "PLL001"]
    )
    data = json.loads(res.output)
    assert {f["rule_id"] for f in data["findings"]} == {"PLL001"}
    assert len({f["file"] for f in data["findings"]}) >= 3
