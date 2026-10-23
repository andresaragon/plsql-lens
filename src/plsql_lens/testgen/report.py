"""Metrics report (JSON) and JUnit XML for a set of unit results."""

from __future__ import annotations

import xml.etree.ElementTree as ET
from collections.abc import Sequence
from typing import Any

from .loop import UnitResult, result_to_dict


def _rate(n: float, d: float) -> float | None:
    return round(n / d, 4) if d else None


def _summary(rs: Sequence[UnitResult]) -> dict[str, Any]:
    tests = sum(r.tests for r in rs)
    passed = sum(r.passed for r in rs)
    cost = sum(r.cost_usd for r in rs)
    return {
        "units": len(rs),
        "compiled": sum(r.compiled for r in rs),
        "ran": sum(r.ran for r in rs),
        "compile_rate": _rate(sum(r.compiled for r in rs), len(rs)),
        "run_rate": _rate(sum(r.ran for r in rs), len(rs)),
        "tests": tests,
        "passed": passed,
        "failed": sum(r.failed for r in rs),
        "errored": sum(r.errored for r in rs),
        "skipped": sum(r.skipped for r in rs),
        "pass_rate": _rate(passed, tests),
        "repair_rounds": sum(r.repair_rounds for r in rs),
        "assertions": sum(r.assertions for r in rs),
        "assertions_per_test": _rate(sum(r.assertions for r in rs), tests),
        "calls": sum(r.calls for r in rs),
        "input_tokens": sum(r.input_tokens for r in rs),
        "output_tokens": sum(r.output_tokens for r in rs),
        "cost_usd": round(cost, 6),
        "cost_usd_per_test": round(cost / tests, 6) if tests else None,
        "cost_usd_per_unit": round(cost / len(rs), 6) if rs else None,
    }


def build_report(results: Sequence[UnitResult]) -> dict[str, Any]:
    by_level = {
        lvl: _summary([r for r in results if r.difficulty == lvl])
        for lvl in ("easy", "medium", "hard")
        if any(r.difficulty == lvl for r in results)
    }
    return {
        "units": [result_to_dict(r) for r in results],
        "total": _summary(results),
        "by_difficulty": by_level,
    }


def to_junit(results: Sequence[UnitResult]) -> str:
    root = ET.Element("testsuites")
    for r in results:
        cases = r.cases or [
            {"name": "compile", "status": "errored", "message": r.compile_error or r.run_error}
        ]
        suite = ET.SubElement(
            root,
            "testsuite",
            name=r.id,
            tests=str(len(cases)),
            failures=str(sum(c["status"] == "failed" for c in cases)),
            errors=str(sum(c["status"] == "errored" for c in cases)),
        )
        for c in cases:
            tc = ET.SubElement(suite, "testcase", classname=r.id, name=c["name"])
            if c["status"] in ("failed", "errored"):
                tag = "failure" if c["status"] == "failed" else "error"
                ET.SubElement(tc, tag, message=c["message"][:500]).text = c["message"]
            elif c["status"] == "skipped":
                ET.SubElement(tc, "skipped")
    root.set("tests", str(sum(int(s.get("tests", 0)) for s in root)))
    root.set("failures", str(sum(int(s.get("failures", 0)) for s in root)))
    root.set("errors", str(sum(int(s.get("errors", 0)) for s in root)))
    ET.indent(root)
    return ET.tostring(root, encoding="unicode", xml_declaration=False) + "\n"
