from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.testgen import (
    SqlplusOracle,
    Target,
    UnitResult,
    build_report,
    count_assertions,
    extract_code,
    load_manifest,
    parse_junit,
    run_committed,
    to_junit,
)
from plsql_lens.testgen.oracle import OracleError
from plsql_lens.testgen.prompt import build_generation_prompt

ROOT = Path(__file__).resolve().parents[2]
FAKE = ROOT / "tests" / "fixtures" / "testgen" / "fake_sqlplus.py"
MANIFEST = ROOT / "tests" / "fixtures" / "testgen" / "manifest.json"


def oracle() -> SqlplusOracle:
    return SqlplusOracle(f"{sys.executable} {FAKE}")


def test_extract_code_prefers_the_fenced_block() -> None:
    assert extract_code("noise\n```sql\ncreate x;\n/\n```\nmore") == "create x;\n/\n"
    assert extract_code("plain") == "plain\n"


def test_count_assertions() -> None:
    assert count_assertions("ut.expect(1).to_equal(1); UT.EXPECT (2).to_be_null();") == 2


def test_parse_junit_statuses() -> None:
    xml = (
        '<testsuites><testsuite><testcase name="a"/><testcase name="b"><failure message="m"/>'
        '</testcase><testcase name="c"><error>e</error></testcase><testcase name="d"><skipped/>'
        "</testcase></testsuite></testsuites>"
    )
    assert [c["status"] for c in parse_junit(xml)] == ["passed", "failed", "errored", "skipped"]


def test_sqlplus_oracle_compile_and_run_via_fake_command() -> None:
    o = oracle()
    assert o.compile("create package body x as end;", "test_x").ok
    bad = o.compile("-- BROKEN_BODY", "test_x")
    assert not bad.ok and "PLS-00201" in bad.errors
    assert "missing" in o.compile("-- NO_BODY", "test_x").errors
    cases = parse_junit(o.run_tests("test_x"))
    assert [c["status"] for c in cases] == ["passed", "failed", "errored"]


def test_sqlplus_oracle_reports_a_failing_command() -> None:
    with pytest.raises(OracleError):
        oracle().run_script("-- FAIL_RUN")


def test_run_committed_uses_meta_and_marks_missing_tests(tmp_path: Path) -> None:
    t1 = Target("a", "p.a", ("x",), "easy", "r")
    t2 = Target("b", "p.b", ("x",), "hard", "r")
    (tmp_path / "a.sql").write_text("ut.expect(1).to_equal(1);")
    (tmp_path / "a.meta.json").write_text(
        json.dumps({"calls": 2, "cost_usd": 0.5, "repair_rounds": 1})
    )
    ra, rb = run_committed([t1, t2], tmp_path, oracle())
    assert ra.compiled and ra.ran and (ra.passed, ra.failed, ra.errored) == (1, 1, 1)
    assert ra.calls == 2 and ra.repair_rounds == 1 and ra.cost_usd == 0.5
    assert not rb.compiled and "no committed test" in rb.compile_error


def test_report_groups_by_difficulty_and_junit_marks_compile_failures() -> None:
    ok = UnitResult("a", "p.a", "easy", compiled=True, ran=True, tests=2, passed=2, assertions=3)
    bad = UnitResult("b", "p.b", "hard", compile_error="PLS-1")
    report = build_report([ok, bad])
    assert set(report["by_difficulty"]) == {"easy", "hard"}
    assert report["total"]["compile_rate"] == 0.5 and report["total"]["pass_rate"] == 1.0
    assert 'name="compile"' in to_junit([bad])


def test_prompt_pulls_foreign_key_parents_into_the_ddl_context() -> None:
    t = next(t for t in load_manifest(MANIFEST) if t.id == "pkg_hr_stats_headcount")
    prompt = build_generation_prompt(t, ROOT).lower()
    assert "create table employees" in prompt
    assert "create table jobs" in prompt and "create table departments" in prompt
    assert "foreign key" in prompt


def test_prompt_for_a_standalone_unit_has_no_package_spec() -> None:
    t = next(t for t in load_manifest(MANIFEST) if t.id == "hr_secure_dml")
    assert "Package specification" not in build_generation_prompt(t, ROOT)


def test_cli_testgen_suite_and_setup_need_an_oracle(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.delenv("PLSQL_LENS_SQLPLUS", raising=False)
    runner = CliRunner()
    assert runner.invoke(app, ["testgen-suite"]).exit_code != 0
    assert runner.invoke(app, ["testgen-setup"]).exit_code != 0


def test_cli_testgen_suite_and_setup_with_a_fake_sqlplus(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    monkeypatch.setenv("PLSQL_LENS_SQLPLUS", f"{sys.executable} {FAKE}")
    runner = CliRunner()
    res = runner.invoke(app, ["testgen-setup", "--log", str(tmp_path / "setup.log")])
    assert res.exit_code == 0 and "setup scripts" in res.output
    res = runner.invoke(
        app,
        ["testgen-suite", "--only", "pkg_calc_clamp", "--report-dir", str(tmp_path)],
    )
    assert res.exit_code == 0, res.output
    assert json.loads((tmp_path / "report.json").read_text())["total"]["units"] == 1
    assert (tmp_path / "junit.xml").read_text().startswith("<testsuites")
