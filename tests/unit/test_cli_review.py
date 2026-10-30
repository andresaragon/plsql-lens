"""Acceptance tests for ``review --fail-on`` (issue #13)."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import pytest
from typer.testing import CliRunner

from plsql_lens.cli import app

ROOT = Path(__file__).resolve().parents[2]
FIX = ROOT / "tests" / "fixtures" / "rules"
HIGH = str(FIX / "PLL001" / "pos_1.pkb")  # only a `high` finding
MEDIUM = str(FIX / "PLL003" / "pos_1.pkb")  # only a `medium` finding
CLEAN = str(FIX / "PLL003" / "neg_1.pkb")  # no findings


# SHA-256 of `review corpus/logger/logger.pkb` captured from origin/main (f1588b0) before
# --fail-on existed. docs/reports/phase-2/review.json cannot serve as the baseline: it predates
# the PLL006 tuning and already differs from main by six findings.
BASELINE_SHA256 = {
    None: "b9f77560e01f17ebcce4ce9f386fb2d075b413b29a67b674e243af7cdc2ac411",  # default (table)
    "json": "d23cf6b4f62b83ec3b2124baf42a01f41723cd37ae974d33fd00bc5f7c632288",
    "sarif": "182578fb1e053bde8c702a99b2dcb48cf793e4c7d1134515ea1b023dc203af93",
}


@pytest.mark.parametrize("fmt", [None, "json", "sarif"])
def test_default_is_never_and_output_is_byte_identical_to_main(
    fmt: str | None, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.chdir(ROOT)
    args = ["review", "corpus/logger/logger.pkb"] + (["--format", fmt] if fmt else [])
    res = CliRunner().invoke(app, args, catch_exceptions=False)
    assert res.exit_code == 0
    assert hashlib.sha256(res.stdout.encode()).hexdigest() == BASELINE_SHA256[fmt]


def test_explicit_never_never_fails_even_with_high_findings() -> None:
    res = CliRunner().invoke(app, ["review", HIGH, "--fail-on", "never"])
    assert res.exit_code == 0 and "PLL001" in res.output


@pytest.mark.parametrize("fmt", ["json", "sarif"])
def test_fail_on_high_with_high_finding_exits_1_and_writes_output(tmp_path: Path, fmt: str) -> None:
    out = tmp_path / f"r.{fmt}"
    res = CliRunner().invoke(
        app, ["review", HIGH, "--format", fmt, "-o", str(out), "--fail-on", "high"]
    )
    assert res.exit_code == 1
    doc = json.loads(out.read_text())  # file exists and is valid JSON / SARIF
    if fmt == "json":
        assert doc["findings"] and {f["rule_id"] for f in doc["findings"]} == {"PLL001"}
    else:
        assert doc["version"] == "2.1.0"
        results = doc["runs"][0]["results"]
        assert results and {r["ruleId"] for r in results} == {"PLL001"}


def test_fail_on_high_still_prints_output_to_stdout_before_exiting() -> None:
    res = CliRunner().invoke(app, ["review", HIGH, "--format", "json", "--fail-on", "high"])
    assert res.exit_code == 1
    assert json.loads(res.stdout)["findings"][0]["rule_id"] == "PLL001"


def test_fail_on_high_with_only_medium_findings_exits_0() -> None:
    res = CliRunner().invoke(app, ["review", MEDIUM, "--fail-on", "high"])
    assert res.exit_code == 0 and "PLL003" in res.output


@pytest.mark.parametrize(
    ("level", "code"),
    [("never", 0), ("info", 1), ("low", 1), ("medium", 1), ("high", 0)],
)
def test_threshold_is_inclusive(level: str, code: int) -> None:
    res = CliRunner().invoke(app, ["review", MEDIUM, "--fail-on", level])
    assert res.exit_code == code


@pytest.mark.parametrize("level", ["never", "info", "low", "medium", "high"])
def test_no_findings_exits_0_at_any_threshold(level: str) -> None:
    res = CliRunner().invoke(app, ["review", CLEAN, "--fail-on", level])
    assert res.exit_code == 0


def test_invalid_fail_on_value_exits_2() -> None:
    res = CliRunner().invoke(app, ["review", HIGH, "--fail-on", "critical"])
    assert res.exit_code == 2
