"""Phase F3 acceptance tests: utPLSQL test generation + execution (SPEC section 3, F3).

No network, Docker, API key or ``claude`` binary: the LLM and Oracle are replaced by fakes here.
The same pipeline against a real Oracle is exercised by tests/integration/test_f3_oracle.py.
"""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

import pytest
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.llm import FakeProvider, LLMResponse
from plsql_lens.testgen import (
    CompileResult,
    TestGenerator,
    build_report,
    load_manifest,
    resolve_unit,
    run_target,
    to_junit,
)

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "tests" / "fixtures" / "testgen" / "manifest.json"
GENERATED = ROOT / "tests" / "generated"


def test_manifest_has_at_least_20_units_with_mixed_difficulty() -> None:
    targets = load_manifest(MANIFEST)
    assert len(targets) >= 20
    assert len({t.id for t in targets}) == len(targets)
    levels = {lvl: sum(t.difficulty == lvl for t in targets) for lvl in ("easy", "medium", "hard")}
    assert all(n >= 5 for n in levels.values()), levels  # not only the easy ones
    assert all(t.reason.strip() for t in targets)


def test_every_target_unit_resolves_to_a_unit_with_a_body() -> None:
    for t in load_manifest(MANIFEST):
        unit = resolve_unit(t, ROOT)
        assert unit.has_body, t.id
        for rel in (*t.source_files, *t.ddl_files, *t.install):
            assert (ROOT / rel).is_file(), f"{t.id}: missing {rel}"


def test_no_target_comes_from_outside_the_notice() -> None:
    notice = (ROOT / "NOTICE").read_text()
    for t in load_manifest(MANIFEST):
        for rel in t.source_files:
            assert rel.startswith(("tests/fixtures/testgen/", "corpus/")), rel
            if rel.startswith("corpus/"):
                assert rel.split("/")[1] in notice


@pytest.mark.parametrize("t", load_manifest(MANIFEST), ids=lambda t: t.id)
def test_generated_test_is_committed_and_shaped_like_utplsql(t) -> None:  # type: ignore[no-untyped-def]
    path = GENERATED / f"{t.id}.sql"
    assert path.is_file(), f"run `make testgen-f3` and commit {path.relative_to(ROOT)}"
    code = path.read_text()
    assert "--%suite" in code and "--%test" in code and "ut.expect" in code
    assert re.search(rf"package\s+body\s+{t.test_package}\b", code, re.I)


# ---- end-to-end with fakes: generate -> compile -> repair (<= N rounds) -> run -> report -------

GOOD = """create or replace package {pkg} as
  --%suite({pkg})
  --%test(adds)
  procedure adds;
end;
/
create or replace package body {pkg} as
  procedure adds is begin ut.expect(1 + 1).to_equal(2); end;
end;
/
"""
BAD = GOOD.replace("ut.expect", "ut.expekt")

JUNIT = (
    '<testsuites tests="1" failures="0" errors="0"><testsuite name="{pkg}" tests="1" failures="0" '
    'errors="0"><testcase classname="{pkg}" name="adds"/></testsuite></testsuites>'
)


@dataclass
class FakeOracle:
    """Compiles only code that does not contain the misspelled ``ut.expekt``."""

    compile_calls: int = 0

    def compile(self, code: str, test_package: str) -> CompileResult:
        self.compile_calls += 1
        if "ut.expekt" in code:
            return CompileResult(False, "PLS-00201: identifier 'UT.EXPEKT' must be declared")
        return CompileResult(True, "")

    def run_tests(self, test_package: str) -> str:
        return JUNIT.format(pkg=test_package)


def _target():  # type: ignore[no-untyped-def]
    return next(t for t in load_manifest(MANIFEST) if t.difficulty == "easy")


def _generator(replies: list[str]) -> tuple[TestGenerator, list[str]]:
    seen: list[str] = []

    class Seq:
        def complete(self, prompt: str) -> LLMResponse:
            seen.append(prompt)
            text = replies[min(len(seen) - 1, len(replies) - 1)]
            return LLMResponse(f"```sql\n{text}\n```", 1000, 400, 0.01, "fake-model")

    return TestGenerator(Seq(), ROOT), seen


def test_loop_repairs_a_compile_error_with_the_oracle_message() -> None:
    t = _target()
    gen, prompts = _generator([BAD.format(pkg=t.test_package), GOOD.format(pkg=t.test_package)])
    res = run_target(t, gen, FakeOracle(), max_repairs=2)
    assert res.compiled and res.ran and res.repair_rounds == 1
    assert "PLS-00201" in prompts[1]  # the Oracle error went back to the model
    assert (res.tests, res.passed, res.failed, res.errored) == (1, 1, 0, 0)
    assert res.calls == 2 and res.input_tokens == 2000 and res.cost_usd == pytest.approx(0.02)
    assert res.assertions == 1


def test_loop_gives_up_after_max_repair_rounds() -> None:
    t = _target()
    gen, _ = _generator([BAD.format(pkg=t.test_package)])
    oracle = FakeOracle()
    res = run_target(t, gen, oracle, max_repairs=2)
    assert not res.compiled and not res.ran and res.repair_rounds == 2
    assert oracle.compile_calls == 3  # initial + 2 repairs, never more
    assert "PLS-00201" in res.compile_error


def test_max_repairs_zero_means_no_repair() -> None:
    t = _target()
    gen, prompts = _generator([BAD.format(pkg=t.test_package)])
    res = run_target(t, gen, FakeOracle(), max_repairs=0)
    assert not res.compiled and res.repair_rounds == 0 and len(prompts) == 1


def test_prompt_contains_signature_source_and_ddl() -> None:
    t = next(t for t in load_manifest(MANIFEST) if t.ddl_files)
    gen, prompts = _generator([GOOD.format(pkg=t.test_package)])
    run_target(t, gen, FakeOracle(), max_repairs=0)
    p = prompts[0]
    assert t.unit.split(".")[-1].lower() in p.lower()
    assert "--%suite" in p and "ut.expect" in p
    assert "create table" in p.lower()


def test_report_and_junit_aggregate_metrics() -> None:
    t = _target()
    gen, _ = _generator([BAD.format(pkg=t.test_package), GOOD.format(pkg=t.test_package)])
    results = [run_target(t, gen, FakeOracle(), max_repairs=2)]
    report = build_report(results)
    total = report["total"]
    assert total["units"] == 1 and total["compile_rate"] == 1.0 and total["run_rate"] == 1.0
    assert total["pass_rate"] == 1.0 and total["repair_rounds"] == 1
    assert total["assertions_per_test"] == 1.0
    assert total["cost_usd_per_test"] == pytest.approx(0.02)
    json.dumps(report)  # serialisable
    root = ET.fromstring(to_junit(results))
    assert root.tag == "testsuites"
    assert root.find(".//testcase") is not None


def test_cli_testgen_writes_a_test_file_from_recordings(tmp_path: Path) -> None:
    t = _target()
    from plsql_lens.testgen import build_generation_prompt

    prompt = build_generation_prompt(t, ROOT)
    rec = tmp_path / "rec.json"
    FakeProvider(
        {prompt: LLMResponse(f"```sql\n{GOOD.format(pkg=t.test_package)}\n```", 5, 6, 0.0, "m")}
    ).save(rec)
    out = tmp_path / "out"
    src = ROOT / t.source_files[-1]
    res = CliRunner().invoke(
        app,
        ["testgen", str(src), "--unit", t.unit, "--manifest", str(MANIFEST), "--out", str(out),
         "--llm", "fake", "--llm-recordings", str(rec)],
    )  # fmt: skip
    assert res.exit_code == 0, res.output
    assert (out / f"{t.id}.sql").read_text().startswith("create or replace package")
