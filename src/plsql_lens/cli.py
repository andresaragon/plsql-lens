"""Command line interface (thin layer over the library)."""

from __future__ import annotations

import json
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer

from .inventory import build_inventory, collect_files, render_mermaid
from .llm import LLMError, UsageLog, explain_findings, make_provider
from .parser import parse_file
from .rules import RULES, review
from .rules.output import table_notes, to_json, to_sarif, to_table

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
