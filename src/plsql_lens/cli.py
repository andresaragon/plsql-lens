"""Command line interface (thin layer over the library)."""

from __future__ import annotations

import json
from enum import StrEnum
from pathlib import Path
from typing import Annotated

import typer

from .inventory import build_inventory, render_mermaid

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
