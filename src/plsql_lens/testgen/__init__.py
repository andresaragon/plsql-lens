"""utPLSQL test generation and execution."""

from .generate import GeneratedTest, TestGenerator, extract_code
from .loop import (
    UnitResult,
    count_assertions,
    load_meta,
    parse_junit,
    run_committed,
    run_target,
    save_generated,
)
from .oracle import CompileResult, Oracle, OracleError, SqlplusOracle
from .prompt import build_generation_prompt, build_repair_prompt
from .report import build_report, to_junit
from .targets import Manifest, Target, load_manifest, load_manifest_full, resolve_unit

__all__ = [
    "CompileResult",
    "GeneratedTest",
    "Manifest",
    "Oracle",
    "OracleError",
    "SqlplusOracle",
    "Target",
    "TestGenerator",
    "UnitResult",
    "build_generation_prompt",
    "build_report",
    "build_repair_prompt",
    "count_assertions",
    "extract_code",
    "load_manifest",
    "load_manifest_full",
    "load_meta",
    "parse_junit",
    "resolve_unit",
    "run_committed",
    "run_target",
    "save_generated",
    "to_junit",
]
