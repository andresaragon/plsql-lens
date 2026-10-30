"""Acceptance tests for ``plsql-lens migrate`` (F5a): formats, --rules, --fail-on, corpus run."""

from __future__ import annotations

import json
import time
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.migrate import MIGRATION_RULES, migrate_file, migrate_source
from plsql_lens.migrate.output import to_sarif

ROOT = Path(__file__).resolve().parents[2]
FIX = ROOT / "tests" / "fixtures" / "migrate" / "rules"
SCHEMA = json.loads((ROOT / "tests" / "vendor" / "sarif-2.1.0.json").read_text())
HIGH = str(FIX / "MIG011" / "pos_1.pkb")  # a `high` finding (plus nothing lower)
MEDIUM = str(FIX / "MIG005" / "pos_1.pkb")  # a `medium` finding
LOW = str(FIX / "MIG001" / "pos_1.pkb")  # a `low` finding
CLEAN = str(FIX / "MIG001" / "neg_1.pkb")  # no findings

run = CliRunner().invoke


def _errors(doc: object) -> list[str]:
    validator = Draft202012Validator(SCHEMA)
    return [f"{'/'.join(map(str, e.path))}: {e.message}" for e in validator.iter_errors(doc)]


# --- formats ----------------------------------------------------------------------------------


def test_table_is_the_default_format() -> None:
    res = run(app, ["migrate", LOW])
    assert res.exit_code == 0
    assert "MIG001" in res.output and "SEVERITY" in res.output


def test_a_clean_file_prints_no_findings() -> None:
    res = run(app, ["migrate", CLEAN])
    assert res.exit_code == 0 and "No findings" in res.output


def test_json_output_has_the_review_shape_with_mig_ids() -> None:
    res = run(app, ["migrate", HIGH, "--format", "json"])
    assert res.exit_code == 0
    findings = json.loads(res.output)["findings"]
    assert findings and {f["rule_id"] for f in findings} == {"MIG011"}
    assert set(findings[0]) >= {
        "severity",
        "file",
        "line",
        "col",
        "message",
        "rationale",
        "fix_hint",
    }


def test_output_file_option_writes_the_report(tmp_path: Path) -> None:
    out = tmp_path / "sub" / "m.json"
    res = run(app, ["migrate", HIGH, "--format", "json", "-o", str(out)])
    assert res.exit_code == 0 and res.output == ""
    assert json.loads(out.read_text())["findings"]


def test_sarif_output_validates_against_the_sarif_schema(tmp_path: Path) -> None:
    out = tmp_path / "m.sarif"
    res = run(app, ["migrate", str(FIX), "--format", "sarif", "-o", str(out)])
    assert res.exit_code == 0
    doc = json.loads(out.read_text())
    assert _errors(doc) == []
    assert doc["runs"][0]["results"], "the fixtures are full of findings"


# --- the SARIF writer -------------------------------------------------------------------------


def test_to_sarif_lists_the_migration_rules_and_indexes_them_correctly() -> None:
    findings = migrate_file(FIX / "MIG008" / "pos_1.pkb") + migrate_file(
        FIX / "MIG001" / "pos_1.pkb"
    )
    doc = json.loads(to_sarif(findings))
    assert _errors(doc) == []
    rules = doc["runs"][0]["tool"]["driver"]["rules"]
    assert [r["id"] for r in rules] == sorted(MIGRATION_RULES)
    for res in doc["runs"][0]["results"]:
        assert rules[res["ruleIndex"]]["id"] == res["ruleId"]
        assert res["message"]["text"]
    assert {r["ruleId"] for r in doc["runs"][0]["results"]} == {"MIG008", "MIG001"}


def test_to_sarif_of_nothing_is_a_valid_empty_run() -> None:
    doc = json.loads(to_sarif([]))
    assert _errors(doc) == [] and doc["runs"][0]["results"] == []


@pytest.mark.parametrize(
    ("src", "rule", "level"),
    [
        ("a := '';", "MIG011", "error"),
        ("a := sysdate;", "MIG003", "warning"),
        ("a := nvl(b, c);", "MIG001", "note"),
    ],
)
def test_sarif_levels_follow_the_review_mapping(src: str, rule: str, level: str) -> None:
    doc = json.loads(to_sarif(migrate_source(src, "x.sql", [rule])))
    assert [r["level"] for r in doc["runs"][0]["results"]] == [level]


# --- --rules ----------------------------------------------------------------------------------


def test_rules_option_restricts_findings_case_insensitively() -> None:
    res = run(app, ["migrate", str(FIX), "--format", "json", "--rules", "mig001, MIG010"])
    assert res.exit_code == 0
    assert {f["rule_id"] for f in json.loads(res.output)["findings"]} == {"MIG001", "MIG010"}


def test_unknown_rule_is_a_usage_error() -> None:
    res = run(app, ["migrate", LOW, "--rules", "MIG999"])
    assert res.exit_code == 2
    assert (
        run(app, ["migrate", LOW, "--rules", "PLL001"]).exit_code == 2
    )  # review rules are not here


def test_missing_path_is_a_usage_error() -> None:
    assert run(app, ["migrate", "no/such/path.pkb"]).exit_code == 2


# --- --fail-on (same semantics and exit codes as review) --------------------------------------


@pytest.mark.parametrize("fail_on", [None, "never"])
def test_default_never_exits_0_even_with_high_findings(fail_on: str | None) -> None:
    args = ["migrate", HIGH] + (["--fail-on", fail_on] if fail_on else [])
    res = run(app, args)
    assert res.exit_code == 0 and "MIG011" in res.output


@pytest.mark.parametrize(
    ("path", "threshold", "code"),
    [
        (HIGH, "high", 1),
        (MEDIUM, "high", 0),
        (MEDIUM, "medium", 1),
        (LOW, "medium", 0),
        (LOW, "low", 1),
        (LOW, "info", 1),
        (CLEAN, "info", 0),
    ],
)
def test_fail_on_is_an_inclusive_severity_threshold(path: str, threshold: str, code: int) -> None:
    assert run(app, ["migrate", path, "--fail-on", threshold]).exit_code == code


def test_a_failing_run_still_writes_the_full_report(tmp_path: Path) -> None:
    out = tmp_path / "m.sarif"
    res = run(app, ["migrate", HIGH, "--format", "sarif", "-o", str(out), "--fail-on", "high"])
    assert res.exit_code == 1
    assert _errors(json.loads(out.read_text())) == []


def test_invalid_fail_on_value_is_a_usage_error() -> None:
    assert run(app, ["migrate", LOW, "--fail-on", "critical"]).exit_code == 2


# --- the corpus -------------------------------------------------------------------------------


def test_migrate_on_the_corpus_does_not_raise_and_takes_under_a_minute(tmp_path: Path) -> None:
    out = tmp_path / "corpus.json"
    started = time.perf_counter()
    res = run(app, ["migrate", str(ROOT / "corpus"), "--format", "json", "-o", str(out)])
    assert time.perf_counter() - started < 60
    assert res.exit_code == 0, res.output
    assert json.loads(out.read_text())["findings"]


def test_review_is_unchanged_and_has_no_migration_rules() -> None:
    res = run(app, ["review", str(FIX / "MIG011" / "pos_1.pkb"), "--format", "json"])
    assert res.exit_code == 0
    assert not [f for f in json.loads(res.output)["findings"] if f["rule_id"].startswith("MIG")]
    assert "migrate" in run(app, ["--help"]).output
