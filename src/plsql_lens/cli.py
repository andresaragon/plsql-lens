"""Command line interface (thin layer over the library)."""

from __future__ import annotations

import json
import os
import re
from concurrent.futures import ThreadPoolExecutor
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer

from .inventory import build_inventory, collect_files, render_mermaid
from .llm import LLMError, LLMProvider, UsageLog, explain_findings, make_provider
from .parser import parse_file
from .rules import RULES, review
from .rules.output import table_notes, to_json, to_sarif, to_table
from .testgen import (
    SqlplusOracle,
    Target,
    TestGenerator,
    UnitResult,
    build_report,
    load_manifest,
    load_manifest_full,
    load_meta,
    run_committed,
    run_target,
    save_generated,
    to_junit,
)
from .testgen.loop import result_to_dict

SEVERITY_RANK = {"info": 0, "low": 1, "medium": 2, "high": 3}

app = typer.Typer(help="Analyze Oracle PL/SQL packages.", no_args_is_help=True)


class Format(StrEnum):
    json = "json"
    mermaid = "mermaid"


class Level(StrEnum):
    package = "package"
    unit = "unit"


@app.callback()
def main() -> None:
    """PL/SQL Lens."""


@app.command()
def inventory(
    path: Annotated[Path, typer.Argument(exists=True, help="File or directory to analyze.")],
    fmt: Annotated[Format, typer.Option("--format", help="Output format.")] = Format.json,
    output: Annotated[Path | None, typer.Option("-o", "--output", help="Write to a file.")] = None,
    level: Annotated[Level, typer.Option(help="Mermaid granularity.")] = Level.package,
) -> None:
    """Inventory units and call graph for PATH."""
    inv = build_inventory([path])
    text = (
        json.dumps(inv.to_dict(), indent=2) + "\n"
        if fmt is Format.json
        else render_mermaid(inv, level.value)
    )
    if output is None:
        typer.echo(text, nl=False)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text)


class ReviewFormat(StrEnum):
    table = "table"
    json = "json"
    sarif = "sarif"


@app.command(name="review")
def review_cmd(
    path: Annotated[Path, typer.Argument(exists=True, help="File or directory to review.")],
    fmt: Annotated[ReviewFormat, typer.Option("--format", help="Output format.")] = (
        ReviewFormat.table
    ),
    output: Annotated[Path | None, typer.Option("-o", "--output", help="Write to a file.")] = None,
    rules: Annotated[
        str | None, typer.Option("--rules", help="Comma-separated rule ids (default: all).")
    ] = None,
    explain: Annotated[
        bool, typer.Option("--explain", help="Ask an LLM to explain findings (never changes them).")
    ] = False,
    llm: Annotated[str, typer.Option("--llm", help="claude-cli | anthropic-api | fake")] = (
        "claude-cli"
    ),
    llm_model: Annotated[str | None, typer.Option("--llm-model")] = None,
    llm_recordings: Annotated[
        Path | None, typer.Option("--llm-recordings", help="Recorded responses (fake provider).")
    ] = None,
    explain_max: Annotated[
        int, typer.Option("--explain-max", help="Max findings sent to the LLM (most severe first).")
    ] = 10,
) -> None:
    """Run the review rules on PATH."""
    selected = [r.strip().upper() for r in rules.split(",")] if rules else None
    unknown = [r for r in selected or [] if r not in RULES]
    if unknown:
        raise typer.BadParameter(f"unknown rule(s): {', '.join(unknown)}", param_hint="--rules")
    findings = []
    sources: dict[str, str] = {}
    for f in collect_files([path]):
        ir = parse_file(f)
        found = review(ir, selected)
        if found and explain:
            sources[str(f)] = f.read_text(encoding="utf-8", errors="replace")
        findings.extend(found)
    notes = None
    usage = None
    if explain:
        try:
            provider = make_provider(llm, model=llm_model, recordings=llm_recordings)
        except LLMError as e:
            raise typer.BadParameter(str(e), param_hint="--llm") from e
        order = sorted(range(len(findings)), key=lambda i: -SEVERITY_RANK[findings[i].severity])
        log = UsageLog()
        done = explain_findings([findings[i] for i in order], sources, provider, log, explain_max)
        by_index = {i: e for i, e in zip(order, done, strict=True)}
        notes = [(by_index[i].explanation, by_index[i].patch) for i in range(len(findings))]
        usage = log.to_dict()
        failures = [e.error for e in done if e.error and "limit" not in e.error]
        if failures:
            typer.echo(
                f"warning: {len(failures)} finding(s) not explained: {failures[0]}", err=True
            )
        typer.echo(
            f"LLM usage: {log.calls} calls, {log.input_tokens} in / "
            f"{log.output_tokens} out tokens, "
            f"cost {usage['cost_usd']}",
            err=True,
        )
    if fmt is ReviewFormat.table:
        text = to_table(findings) + (table_notes(findings, notes) if notes else "")
    elif fmt is ReviewFormat.json:
        text = to_json(findings, notes, usage)
    else:
        text = to_sarif(findings, notes)
    if output is None:
        typer.echo(text, nl=False)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text)


# ---- testgen -------------------------------------------------------------------------------

TESTGEN_MODEL = "claude-sonnet-5-5"  # SPEC §9: test generation uses Sonnet
DEFAULT_MANIFEST = Path("tests/fixtures/testgen/manifest.json")
DEFAULT_TESTS = Path("tests/generated")


def _oracle_from_env() -> SqlplusOracle | None:
    cmd = os.environ.get("PLSQL_LENS_SQLPLUS")
    return SqlplusOracle(cmd) if cmd else None


def _provider(llm: str, model: str | None, recordings: Path | None) -> LLMProvider:
    try:
        return make_provider(llm, model=model or TESTGEN_MODEL, recordings=recordings)
    except LLMError as e:
        raise typer.BadParameter(str(e), param_hint="--llm") from e


@app.command()
def testgen(
    path: Annotated[Path, typer.Argument(exists=True, help="Source file containing the unit.")],
    unit: Annotated[str, typer.Option("--unit", help="PKG.PROC or a standalone name.")],
    manifest: Annotated[Path | None, typer.Option(help="Manifest with DDL context.")] = None,
    out: Annotated[Path, typer.Option(help="Directory for the generated test.")] = DEFAULT_TESTS,
    run: Annotated[bool, typer.Option("--run", help="Compile/repair/run on Oracle.")] = False,
    max_repairs: Annotated[int, typer.Option(help="Repair rounds after a compile error.")] = 2,
    llm: Annotated[str, typer.Option("--llm", help="claude-cli | anthropic-api | fake")] = (
        "claude-cli"
    ),
    llm_model: Annotated[str | None, typer.Option("--llm-model")] = None,
    llm_recordings: Annotated[Path | None, typer.Option("--llm-recordings")] = None,
) -> None:
    """Generate a utPLSQL test package for one unit (calls the LLM; costs money)."""
    target = _find_target(path, unit, manifest)
    gen = TestGenerator(_provider(llm, llm_model, llm_recordings), Path.cwd())
    oracle = _oracle_from_env() if run else None
    if run and oracle is None:
        raise typer.BadParameter("--run needs PLSQL_LENS_SQLPLUS (see docker/README.md)")
    if oracle is None:
        g = gen.generate(target)
        res = UnitResult(target.id, target.unit, target.difficulty, code=g.code)
        res.calls, res.input_tokens = 1, g.response.input_tokens
        res.output_tokens, res.cost_usd = g.response.output_tokens, g.response.cost_usd or 0.0
    else:
        res = run_target(target, gen, oracle, max_repairs)
    save_generated(res, out, llm_model or TESTGEN_MODEL)
    typer.echo(f"wrote {out / (target.id + '.sql')}")
    typer.echo(f"LLM: {res.calls} call(s), {res.input_tokens} in / {res.output_tokens} out tokens, "
               f"cost {res.cost_usd:.4f} USD", err=True)  # fmt: skip
    if oracle is not None:
        typer.echo(json.dumps(result_to_dict(res), indent=2))


def _find_target(path: Path, unit: str, manifest: Path | None) -> Target:
    if manifest is not None:
        for t in load_manifest(manifest):
            if t.unit.lower() == unit.lower():
                return t
        raise typer.BadParameter(f"unit {unit} is not in {manifest}", param_hint="--unit")
    rel = str(path)
    return Target(re.sub(r"\W+", "_", unit.lower()), unit, (rel,), "adhoc", "ad-hoc run")


def _terminated(script: str) -> str:
    """Make sure a script ends with ``/`` or ``;`` without re-running its last statement."""
    tail = script.rstrip()
    return script + ("\n" if tail.endswith(("/", ";")) else "\n/\n")


@app.command(name="testgen-setup")
def testgen_setup(
    manifest: Annotated[
        Path, typer.Option(help="Manifest listing setup scripts.")
    ] = DEFAULT_MANIFEST,
    log: Annotated[Path | None, typer.Option(help="Write the full sqlplus output here.")] = None,
) -> None:
    """Install the target objects (Logger, HR, test packages) into the configured Oracle schema."""
    oracle = _oracle_from_env()
    if oracle is None:
        raise typer.BadParameter("needs PLSQL_LENS_SQLPLUS (see docker/README.md)")
    scripts = load_manifest_full(manifest).setup
    body = "\n".join(_terminated(Path(s).read_text(errors="replace")) for s in scripts)
    probe = (
        "\nset heading off\nset pagesize 0\nset linesize 1000\n"
        "select 'PLL_ERR|' || type || '|' || name || '|' || line || ':' || position || ' ' || text "
        "from user_errors order by name, type, sequence;\n"
        "select 'PLL_INVALID|' || object_type || '|' || object_name from user_objects "
        "where status <> 'VALID';\n"
    )
    out = oracle.run_script(body + probe)
    if log is not None:
        log.parent.mkdir(parents=True, exist_ok=True)
        log.write_text(out)
    lines = out.splitlines()
    errs: list[str] = []
    for i, ln in enumerate(lines):
        if re.match(r"^(ORA|SP2|PLS)-\d+|^PLL_(ERR|INVALID)\|", ln):
            if ln.startswith(("ORA-", "SP2-", "PLS-")):  # show the statement that failed
                errs.extend(
                    x for x in lines[max(0, i - 4) : i] if x.strip() and "ERROR at" not in x
                )
            errs.append(ln)
    typer.echo(f"ran {len(scripts)} setup scripts; {len(errs)} error line(s)")
    for ln in errs[:60]:
        typer.echo("  " + ln[:300])


@app.command(name="testgen-suite")
def testgen_suite(
    manifest: Annotated[Path, typer.Option(help="Manifest with the targets.")] = DEFAULT_MANIFEST,
    tests: Annotated[Path, typer.Option(help="Directory of generated tests.")] = DEFAULT_TESTS,
    report_dir: Annotated[Path, typer.Option(help="Where report.json / junit.xml go.")] = Path(
        "docs/reports/phase-3"
    ),
    generate: Annotated[
        bool, typer.Option("--generate", help="Regenerate tests with the LLM (COSTS MONEY).")
    ] = False,
    repair_from: Annotated[
        Path | None, typer.Option(help="Repair tests that failed to compile in this report.json.")
    ] = None,
    only: Annotated[
        list[str] | None, typer.Option("--only", help="Target id (repeatable).")
    ] = None,
    max_repairs: Annotated[int, typer.Option(help="Repair rounds with a live Oracle.")] = 2,
    jobs: Annotated[int, typer.Option(help="Parallel LLM calls when generating/repairing.")] = 4,
    llm: Annotated[str, typer.Option("--llm")] = "claude-cli",
    llm_model: Annotated[str | None, typer.Option("--llm-model")] = None,
    llm_recordings: Annotated[Path | None, typer.Option("--llm-recordings")] = None,
) -> None:
    """Run the committed tests on Oracle and write the metrics report (no LLM unless asked)."""
    targets = [t for t in load_manifest(manifest) if not only or t.id in only]
    oracle = _oracle_from_env()
    if generate or repair_from:
        gen = TestGenerator(_provider(llm, llm_model, llm_recordings), Path.cwd())
        model = llm_model or TESTGEN_MODEL
        failed: dict[str, dict[str, object]] = {}
        if repair_from:
            old = {u["id"]: u for u in json.loads(repair_from.read_text())["units"]}
            failed = {i: u for i, u in old.items() if not u["compiled"]}

        def one(t: Target) -> UnitResult:
            if repair_from:
                g = gen.repair(
                    t, (tests / f"{t.id}.sql").read_text(), str(failed[t.id]["compile_error"])
                )
                res = UnitResult(t.id, t.unit, t.difficulty, code=g.code)
                meta = load_meta(tests, t.id)
                res.calls = int(meta.get("calls", 0)) + 1  # type: ignore[call-overload]
                res.input_tokens = int(meta.get("input_tokens", 0)) + g.response.input_tokens  # type: ignore[call-overload]
                res.output_tokens = int(meta.get("output_tokens", 0)) + g.response.output_tokens  # type: ignore[call-overload]
                res.cost_usd = float(meta.get("cost_usd", 0.0)) + (g.response.cost_usd or 0.0)  # type: ignore[arg-type]
                res.repair_rounds = int(meta.get("repair_rounds", 0)) + 1  # type: ignore[call-overload]
                return res
            if oracle is not None:
                return run_target(t, gen, oracle, max_repairs)
            g = gen.generate(t)
            res = UnitResult(t.id, t.unit, t.difficulty, code=g.code, calls=1)
            res.input_tokens, res.output_tokens = g.response.input_tokens, g.response.output_tokens
            res.cost_usd = g.response.cost_usd or 0.0
            return res

        todo = [t for t in targets if not repair_from or t.id in failed]
        with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
            for t, res in zip(todo, pool.map(one, todo), strict=True):
                save_generated(res, tests, model)
                typer.echo(
                    f"{t.id}: wrote test ({res.calls} call(s), {res.cost_usd:.4f} USD)", err=True
                )
        return
    if oracle is None:
        raise typer.BadParameter("running tests needs PLSQL_LENS_SQLPLUS (see docker/README.md)")
    results = run_committed(targets, tests, oracle)
    report_dir.mkdir(parents=True, exist_ok=True)
    (report_dir / "report.json").write_text(json.dumps(build_report(results), indent=2) + "\n")
    (report_dir / "junit.xml").write_text(to_junit(results))
    t_ = build_report(results)["total"]
    typer.echo(
        f"units {t_['units']}: compiled {t_['compiled']}, ran {t_['ran']}, tests {t_['tests']}, "
        f"passed {t_['passed']}, failed {t_['failed']}, errored {t_['errored']}"
    )
