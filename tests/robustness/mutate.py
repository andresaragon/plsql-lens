"""Seeded source mutations and a guarded parse + review run (helpers for issue #16)."""

from __future__ import annotations

import hashlib
import json
import random
import re
import signal
import tempfile
import time
import traceback
from collections.abc import Callable, Iterator
from dataclasses import dataclass
from functools import cache
from pathlib import Path
from typing import Any

from plsql_lens import parse_file
from plsql_lens.parser import FileIR
from plsql_lens.rules import review

ROOT = Path(__file__).resolve().parents[2]
SEED = 20261030
MIN_MUTATIONS = 2000
MUTATIONS = 2400
PARSE_LIMIT_S = 2.0
REVIEW_LIMIT_S = 5.0  # hang guard only: the issue sets the 2 s budget for parse_file

SEED_DIRS = ("corpus", "tests/fixtures")
SEED_SUFFIXES = {".pkb", ".pks", ".sql", ".plb", ".tps", ".tpb", ".trg", ".prc", ".fnc"}
_TOKEN = re.compile(r"\w+|\s+|.", re.DOTALL)


def source_files() -> list[str]:
    """Seed files as sorted repo-relative POSIX paths."""
    found = [
        p.relative_to(ROOT).as_posix()
        for d in SEED_DIRS
        for p in (ROOT / d).rglob("*")
        if p.is_file() and p.suffix.lower() in SEED_SUFFIXES
    ]
    return sorted(found)


@cache
def _text(name: str) -> str:
    return (ROOT / name).read_bytes().decode("utf-8", errors="replace")


@cache
def _tokens(name: str) -> list[str]:
    return _TOKEN.findall(_text(name))


# --- mutation operators: (seed file, text, rng) -> text ---------------------------------------


def _truncate(_n: str, text: str, rng: random.Random) -> str:
    return text[: rng.randrange(len(text) + 1)]


def _delete_token(name: str, text: str, rng: random.Random) -> str:
    toks = _tokens(name)
    i = rng.randrange(len(toks))
    return "".join(toks[:i] + toks[i + 1 :])


def _duplicate_token(name: str, text: str, rng: random.Random) -> str:
    toks = _tokens(name)
    i = rng.randrange(len(toks))
    return "".join(toks[: i + 1] + toks[i:])


def _repeat_span(name: str, text: str, rng: random.Random) -> str:
    """Repeat 1-4 consecutive tokens 10 to ~20000 times (deep nesting, runaway quotes)."""
    toks = _tokens(name)
    i = rng.randrange(len(toks))
    span = toks[i : i + rng.randint(1, 4)]
    times = int(10 ** rng.uniform(1, 4.3))
    times = min(times, 400_000 // max(1, len("".join(span))))
    return "".join(toks[:i] + span * times + toks[i + len(span) :])


def _insert(text: str, rng: random.Random, pieces: list[str]) -> str:
    at = rng.randrange(len(text) + 1)
    return text[:at] + rng.choice(pieces) + text[at:]


def _unclosed_quote(_n: str, text: str, rng: random.Random) -> str:
    return _insert(text, rng, ["'", '"', "q'[", "q'{", "'\n", "n'"])


def _unclosed_comment(_n: str, text: str, rng: random.Random) -> str:
    return _insert(text, rng, ["/*", "/* ", "/**", "--", "/*\n"])


def _change_case(_n: str, text: str, rng: random.Random) -> str:
    mode = rng.choice(["upper", "lower", "swap", "slice"])
    if mode == "upper":
        return text.upper()
    if mode == "lower":
        return text.lower()
    if mode == "swap":
        return text.swapcase()
    a = rng.randrange(len(text) + 1)
    b = rng.randrange(a, len(text) + 1)
    return text[:a] + text[a:b].swapcase() + text[b:]


def _line_endings(_n: str, text: str, rng: random.Random) -> str:
    return text.replace("\n", rng.choice(["\r\n", "\r", "\n\r"]))


def _bom(_n: str, text: str, rng: random.Random) -> str:
    return "﻿" * rng.choice([1, 1, 2]) + text


_SINGLE: dict[str, Callable[[str, str, random.Random], str]] = {
    "truncate": _truncate,
    "delete_token": _delete_token,
    "duplicate_token": _duplicate_token,
    "repeat_span": _repeat_span,
    "unclosed_quote": _unclosed_quote,
    "unclosed_comment": _unclosed_comment,
    "change_case": _change_case,
    "line_endings": _line_endings,
    "bom": _bom,
}


def _compound(name: str, text: str, rng: random.Random) -> str:
    # Token-based operators index the original file, so they only run first in a chain.
    first = rng.choice(list(_SINGLE))
    text = _SINGLE[first](name, text, rng)
    for _ in range(rng.randrange(1, 3)):
        text = _SINGLE[rng.choice(["truncate", "unclosed_quote", "unclosed_comment", "bom"])](
            name, text, rng
        )
    return text


OPERATORS: tuple[str, ...] = (*_SINGLE, "compound")
_ALL = {**_SINGLE, "compound": _compound}


@dataclass(frozen=True)
class Mutation:
    source: str
    operator: str
    data: bytes

    @property
    def digest(self) -> str:
        return hashlib.sha256(self.data).hexdigest()


def generate_mutations(seed: int, count: int) -> Iterator[Mutation]:
    """The same ``seed`` always yields the same list; ``count`` only chooses how long a prefix."""
    rng = random.Random(seed)
    files = source_files()
    for _ in range(count):
        name = rng.choice(files)
        operator = rng.choice(OPERATORS)
        text = _ALL[operator](name, _text(name), rng)
        yield Mutation(name, operator, text.encode("utf-8"))


# --- guarded run ------------------------------------------------------------------------------


class Hang(BaseException):
    """Raised by the alarm; not an ``Exception`` so the code under test cannot swallow it."""


def have_time_limit() -> bool:
    return hasattr(signal, "setitimer") and hasattr(signal, "SIGALRM")


def _on_alarm(_signum: int, _frame: Any) -> None:
    raise Hang("exceeded the time limit")


@dataclass(frozen=True)
class Outcome:
    ok: bool
    stage: str = ""  # "parse" | "review"
    error: str = ""
    where: str = ""
    parse_s: float = 0.0
    review_s: float = 0.0

    @property
    def signature(self) -> str:
        """Stable id of a failure: stage, exception type and where it surfaced.

        Where the alarm or the recursion limit happens to trip is incidental, so a hang keeps only
        the module and a ``RecursionError`` keeps nothing.
        """
        if self.ok:
            return ""
        kind = self.error.split(":")[0]
        where = "*" if kind == "RecursionError" else self.where
        if kind == "Hang":
            where = where.split(":")[0]
        return f"{self.stage}:{kind}:{where}"


def _where(exc: BaseException) -> str:
    frames = [f for f in traceback.extract_tb(exc.__traceback__) if "plsql_lens" in f.filename]
    return f"{Path(frames[-1].filename).name}:{frames[-1].name}" if frames else "?"


_tmp: tempfile.TemporaryDirectory[str] | None = None


def _scratch_file() -> Path:
    global _tmp
    if _tmp is None:
        _tmp = tempfile.TemporaryDirectory(prefix="plsql-lens-robustness-")
    return Path(_tmp.name) / "mutated.pkb"


def _timed(fn: Callable[[], Any], limit_s: float) -> tuple[Any, float]:
    previous = signal.signal(signal.SIGALRM, _on_alarm)
    started = time.perf_counter()
    signal.setitimer(signal.ITIMER_REAL, limit_s)
    try:
        return fn(), time.perf_counter() - started
    finally:
        signal.setitimer(signal.ITIMER_REAL, 0)
        signal.signal(signal.SIGALRM, previous)


def run_guarded(
    data: bytes,
    parse: Callable[[Path], Any] = parse_file,
    review_ir: Callable[[FileIR], Any] = review,
    limit_s: float = PARSE_LIMIT_S,
) -> Outcome:
    """``parse_file`` then ``review`` on mutated bytes; any exception or hang is a failure."""
    path = _scratch_file()
    path.write_bytes(data)
    stage = "parse"
    parse_s = 0.0
    try:
        ir, parse_s = _timed(lambda: parse(path), limit_s)
        if not isinstance(ir, FileIR):
            return Outcome(
                False, stage, f"TypeError: parse_file returned {type(ir).__name__}, not FileIR"
            )
        stage = "review"
        _, review_s = _timed(lambda: review_ir(ir), REVIEW_LIMIT_S)
    except (Exception, Hang) as exc:  # noqa: BLE001 - the point is to catch whatever escapes
        return Outcome(
            False, stage, f"{type(exc).__name__}: {exc}"[:200], _where(exc), parse_s=parse_s
        )
    return Outcome(True, parse_s=parse_s, review_s=review_s)


# --- recorded findings --------------------------------------------------------------------------

FINDINGS_DIR = Path(__file__).resolve().parent / "findings"


@dataclass(frozen=True)
class Finding:
    name: str
    reason: str
    signature: str
    data: bytes


def load_findings() -> list[Finding]:
    """Minimized reproductions: JSON recipes ``{"parts": [[text, times], ...]}``."""
    found = []
    for path in sorted(FINDINGS_DIR.glob("*.json")):
        spec = json.loads(path.read_text())
        data = "".join(text * times for text, times in spec["parts"]).encode("utf-8")
        found.append(Finding(path.stem, spec["reason"], spec["signature"], data))
    return found


def known_signatures() -> set[str]:
    return {f.signature for f in load_findings()}
