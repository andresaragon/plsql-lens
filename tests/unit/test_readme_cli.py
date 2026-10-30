"""The READMEs describe the CLI that exists (issue #12).

* every command of ``plsql_lens.cli.app`` is documented as ``plsql-lens <command>`` in README.md;
* README.md no longer presents F1 as the current status;
* README.md and README.es.md have the same ``##`` structure;
* every ``bash`` example of ``inventory``/``review`` that needs neither Oracle nor a paid LLM is a
  valid invocation (checked with ``--help``, so nothing is parsed, queried or billed).
"""

from __future__ import annotations

import re
import shlex
from pathlib import Path

import pytest
import typer.main
from typer.testing import CliRunner

from plsql_lens.cli import app

ROOT = Path(__file__).resolve().parents[2]
README = ROOT / "README.md"
README_ES = ROOT / "README.es.md"

FENCE = re.compile(r"^```(\w*)\s*$")
CLI_LINE = re.compile(r"^(?:uv run )?plsql-lens (inventory|review|migrate)\b")


def _commands() -> list[str]:
    return sorted(typer.main.get_command(app).commands)  # type: ignore[attr-defined]


def _blocks(text: str) -> list[tuple[str, str]]:
    """(language, body) of every fenced block."""
    blocks: list[tuple[str, str]] = []
    lang: str | None = None
    body: list[str] = []
    for line in text.splitlines():
        m = FENCE.match(line)
        if m and lang is None:
            lang, body = m.group(1), []
        elif m or line.strip() == "```":
            blocks.append((lang or "", "\n".join(body)))
            lang = None
        elif lang is not None:
            body.append(line)
    return blocks


def _headings(text: str) -> list[tuple[str, int]]:
    """``##`` headings outside code fences, each with the number of fenced blocks in its section."""
    out: list[tuple[str, int]] = []
    in_fence = False
    for line in text.splitlines():
        if line.startswith("```"):
            if not in_fence and out:
                title, n = out[-1]
                out[-1] = (title, n + 1)
            in_fence = not in_fence
        elif not in_fence and line.startswith("## "):
            out.append((line, 0))
    return out


def _cli_invocations(text: str) -> list[list[str]]:
    """Arguments (after ``plsql-lens``) of each inventory/review line in a bash block that needs
    neither Oracle nor a paid LLM; ``\\`` continuations are joined and ``# comments`` dropped."""
    found: list[list[str]] = []
    for lang, body in _blocks(text):
        if lang != "bash":
            continue
        for line in body.replace("\\\n", " ").splitlines():
            line = line.strip()
            if not CLI_LINE.match(line):
                continue
            argv = shlex.split(line, comments=True)
            argv = argv[argv.index("plsql-lens") + 1 :]
            uses_fake_llm = "--llm" in argv and argv[argv.index("--llm") + 1] == "fake"
            if "--explain" in argv and not uses_fake_llm:
                continue  # needs a real (paid) LLM
            found.append(argv)
    return found


@pytest.mark.parametrize("command", _commands())
def test_every_cli_command_is_in_the_readme(command: str) -> None:
    pattern = rf"plsql-lens {re.escape(command)}(?![\w-])"
    assert re.search(pattern, README.read_text(encoding="utf-8")), (
        f"README.md does not mention `plsql-lens {command}`"
    )


def test_the_command_list_is_the_one_the_issue_names() -> None:
    assert _commands() == sorted(
        [
            "inventory",
            "review",
            "migrate",
            "testgen",
            "testgen-setup",
            "testgen-suite",
            "bench",
            "bench-llm",
            "bench-external",
        ]
    )


def test_readme_does_not_claim_f1_is_the_status() -> None:
    text = README.read_text(encoding="utf-8")
    assert "Phase F1 (parser & inventory)" not in text
    assert "are planned" not in text


def test_readmes_have_the_same_sections() -> None:
    en = _headings(README.read_text(encoding="utf-8"))
    es = _headings(README_ES.read_text(encoding="utf-8"))
    assert len(en) == len(es), (
        f"README.md has {len(en)} `##` sections, README.es.md has {len(es)}:\n"
        f"{[h for h, _ in en]}\n{[h for h, _ in es]}"
    )
    # order: the n-th section of both files holds the same number of code blocks
    assert [n for _, n in en] == [n for _, n in es]


def test_readme_review_quick_start_covers_formats_rules_and_explain() -> None:
    argvs = [a for a in _cli_invocations(README.read_text(encoding="utf-8")) if a[0] == "review"]
    assert argvs, "README.md has no runnable `plsql-lens review` example"
    formats = {a[a.index("--format") + 1] for a in argvs if "--format" in a}
    assert {"json", "sarif"} <= formats
    assert any("--format" not in a or "table" in formats for a in argvs)  # table (the default)
    assert any("--rules" in a for a in argvs)
    assert "--explain" in README.read_text(encoding="utf-8")


@pytest.mark.parametrize("readme", [README, README_ES], ids=lambda p: p.name)
def test_bash_examples_of_inventory_and_review_are_valid_invocations(readme: Path) -> None:
    argvs = _cli_invocations(readme.read_text(encoding="utf-8"))
    assert argvs, f"{readme.name} has no inventory/review example"
    for argv in argvs:
        res = CliRunner().invoke(app, [*argv, "--help"])
        assert res.exit_code == 0, (
            f"{readme.name}: plsql-lens {' '.join(argv)} --help\n{res.output}"
        )
        assert "Usage" in res.output
