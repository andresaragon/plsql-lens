"""Generate -> compile -> repair (bounded) -> run, and result parsing."""

from __future__ import annotations

import json
import re
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass, field
from pathlib import Path

from ..llm import LLMError
from .generate import GeneratedTest, TestGenerator
from .oracle import Oracle, OracleError
from .targets import Target

_ASSERT = re.compile(r"\but\.expect\s*\(", re.IGNORECASE)


@dataclass
class UnitResult:
    id: str
    unit: str
    difficulty: str
    code: str = ""
    compiled: bool = False
    ran: bool = False
    compile_error: str = ""
    run_error: str = ""
    repair_rounds: int = 0
    tests: int = 0
    passed: int = 0
    failed: int = 0
    errored: int = 0
    skipped: int = 0
    assertions: int = 0
    calls: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    cost_usd: float = 0.0
    cases: list[dict[str, str]] = field(default_factory=list)  # name, status, message


def count_assertions(code: str) -> int:
    return len(_ASSERT.findall(code))


def parse_junit(xml: str) -> list[dict[str, str]]:
    """Test cases of a utPLSQL JUnit report as ``{name, status, message}``."""
    root = ET.fromstring(xml)
    cases = []
    for tc in root.iter("testcase"):
        status, message = "passed", ""
        for tag, st in (("failure", "failed"), ("error", "errored"), ("skipped", "skipped")):
            node = tc.find(tag)
            if node is not None:
                status = st
                message = (node.get("message") or node.text or "").strip()[:2000]
                break
        cases.append({"name": tc.get("name", ""), "status": status, "message": message})
    return cases


def _account(res: UnitResult, g: GeneratedTest) -> None:
    res.calls += 1
    res.input_tokens += g.response.input_tokens
    res.output_tokens += g.response.output_tokens
    res.cost_usd += g.response.cost_usd or 0.0


def _execute(res: UnitResult, target: Target, oracle: Oracle, max_repairs: int,
             generator: TestGenerator | None) -> None:  # fmt: skip
    """Compile ``res.code`` (repairing up to ``max_repairs`` times), then run it."""
    while True:
        comp = oracle.compile(res.code, target.test_package)
        if comp.ok:
            res.compiled, res.compile_error = True, ""
            break
        res.compile_error = comp.errors
        if generator is None or res.repair_rounds >= max_repairs:
            return
        try:
            g = generator.repair(target, res.code, comp.errors)
        except LLMError as e:
            res.compile_error += f"\n[repair failed: {e}]"
            return
        res.repair_rounds += 1
        res.code = g.code
        _account(res, g)
    res.assertions = count_assertions(res.code)
    try:
        cases = parse_junit(oracle.run_tests(target.test_package))
    except (OracleError, ET.ParseError) as e:
        res.run_error = str(e)
        return
    res.ran, res.cases = True, cases
    res.tests = len(cases)
    for status in ("passed", "failed", "errored", "skipped"):
        setattr(res, status, sum(c["status"] == status for c in cases))


def run_target(target: Target, generator: TestGenerator, oracle: Oracle, max_repairs: int = 2,
               code: str | None = None) -> UnitResult:  # fmt: skip
    """Generate (unless ``code`` is given), compile, repair at most ``max_repairs`` times, run."""
    res = UnitResult(target.id, target.unit, target.difficulty)
    if code is None:
        try:
            g = generator.generate(target)
        except LLMError as e:
            res.compile_error = f"[generation failed: {e}]"
            return res
        res.code = g.code
        _account(res, g)
    else:
        res.code = code
    _execute(res, target, oracle, max_repairs, generator)
    return res


# ---- persisted generations: tests/generated/<id>.sql + <id>.meta.json ------------------------


def save_generated(res: UnitResult, out_dir: Path, model: str = "") -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{res.id}.sql").write_text(res.code)
    meta = {k: getattr(res, k) for k in ("calls", "input_tokens", "output_tokens", "cost_usd",
                                         "repair_rounds")}  # fmt: skip
    meta["model"] = model
    (out_dir / f"{res.id}.meta.json").write_text(json.dumps(meta, indent=1) + "\n")


def load_meta(out_dir: Path, target_id: str) -> dict[str, object]:
    p = out_dir / f"{target_id}.meta.json"
    return json.loads(p.read_text()) if p.exists() else {}


def run_committed(targets: list[Target], tests_dir: Path, oracle: Oracle) -> list[UnitResult]:
    """Compile and run the committed tests as they are (no LLM, no repairs).

    Generation cost and repair rounds are taken from the ``.meta.json`` written at generation time.
    """
    results = []
    for t in targets:
        path = tests_dir / f"{t.id}.sql"
        res = UnitResult(t.id, t.unit, t.difficulty)
        meta = load_meta(tests_dir, t.id)
        for k in ("calls", "input_tokens", "output_tokens", "repair_rounds"):
            setattr(res, k, int(meta.get(k, 0)))  # type: ignore[call-overload]
        res.cost_usd = float(meta.get("cost_usd", 0.0))  # type: ignore[arg-type]
        if not path.exists():
            res.compile_error = "no committed test"
        else:
            res.code = path.read_text()
            _execute(res, t, oracle, 0, None)
        results.append(res)
    return results


def result_to_dict(r: UnitResult) -> dict[str, object]:
    d = asdict(r)
    d.pop("code")
    return d
