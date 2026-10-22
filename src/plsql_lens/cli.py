"""Command line interface (thin layer over the library)."""

from __future__ import annotations

import json
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer

from .inventory import build_inventory, collect_files, render_mermaid
from .parser import parse_file
from .rules import RULES, review
from .rules.output import to_json, to_sarif, to_table

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
) -> None:
    """Run the review rules on PATH."""
    selected = [r.strip().upper() for r in rules.split(",")] if rules else None
    unknown = [r for r in selected or [] if r not in RULES]
    if unknown:
        raise typer.BadParameter(f"unknown rule(s): {', '.join(unknown)}", param_hint="--rules")
    findings = []
    for f in collect_files([path]):
        findings.extend(review(parse_file(f), selected))
    render = {
        ReviewFormat.table: to_table,
        ReviewFormat.json: to_json,
        ReviewFormat.sarif: to_sarif,
    }
    text = render[fmt](findings)
    if output is None:
        typer.echo(text, nl=False)
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(text)
