"""F4b (cross-model variant) acceptance tests: the split in docs/benchmarks/external.

Written before the cases exist (red by design); they must not be edited to make them pass.
The split follows the protocol of docs/benchmarks/human/README.md (same markers, same header,
same size targets) but its author is a different LLM family (Gemini through Antigravity), NOT a
human and NOT Claude, and it is labeled as such. These tests only check structure and obvious
mislabels; they never run the rule engine on the cases (that is the adjudication step, which
happens after the cases are sealed).
"""

from __future__ import annotations

import hashlib
import re
from collections import Counter
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
SPLIT = ROOT / "docs" / "benchmarks" / "external"
CASES = SPLIT / "cases"
RULES = [f"PLL00{i}" for i in range(1, 8)]
FILE_RE = re.compile(r"^e(\d{3})\.pkb$")
MARKER_RE = re.compile(r"\b(expect|beyond|clean):\s*(PLL00[1-7])\b")
STRAY_RE = re.compile(r"\b(expect|beyond|clean)\b")
AUTHOR = "-- author: gemini-3.8-flash-high via agy (not human-written)"
DIFFICULTIES = {"easy", "medium", "hard"}
DOMAINS = {
    "library loans",
    "retail store",
    "payroll",
    "ticketing",
    "inventory",
    "hotel booking",
    "school grades",
    "clinic appointments",
    "car rental",
    "logistics tracking",
    "gym memberships",
    "restaurant orders",
    "airline baggage",
    "parking permits",
}
HEADER_LINES = 5

# Static sanity check of the line a marker sits on (code part only, lower-case). Catches obvious
# mislabels without running the rule engine. Applied to `expect` and `clean`; `beyond` can sit
# anywhere.
LINE_CHECK = {
    "PLL001": re.compile(r"when\s+others"),
    "PLL002": re.compile(r"execute\s+immediate|open\s+\w+\s+for\b"),
    "PLL003": re.compile(r"\b(commit|rollback)\b"),
    "PLL004": re.compile(r"\bselect\b"),
    "PLL005": re.compile(r"\b(insert|update|delete|merge|forall)\b"),
    "PLL006": re.compile(r"to_date|to_timestamp|<=|>=|<>|!=|=|<|>"),
    "PLL007": re.compile(r"\d|'"),
}


def case_files() -> list[Path]:
    if not CASES.is_dir():
        return []
    return sorted(p for p in CASES.glob("*.pkb") if FILE_RE.match(p.name))


def split_comment(line: str) -> tuple[str, str]:
    """Return (code, comment) splitting at the first `--` that is outside a string literal."""
    in_str = False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == "'":
            in_str = not in_str
        elif not in_str and line.startswith("--", i):
            return line[:i], line[i:]
        i += 1
    return line, ""


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def markers(path: Path) -> list[tuple[int, str, str, str]]:
    """(line number, kind, rule, code part) for every marker after the header."""
    found = []
    for n, line in enumerate(read_lines(path)[HEADER_LINES:], start=HEADER_LINES + 1):
        code, comment = split_comment(line)
        for kind, rule in MARKER_RE.findall(comment):
            found.append((n, kind, rule, code))
    return found


FILES = case_files()
IDS = [p.name for p in FILES]


def test_split_has_30_to_40_contiguous_cases():
    names = [p.name for p in FILES]
    assert 30 <= len(names) <= 40, f"expected 30-40 cases in {CASES}, found {len(names)}"
    assert names == [f"e{i:03d}.pkb" for i in range(1, len(names) + 1)], "ids must be e001..eNN"


def test_readme_labels_the_split_honestly():
    readme = SPLIT / "README.md"
    assert readme.is_file(), "docs/benchmarks/external/README.md is missing"
    text = readme.read_text(encoding="utf-8").lower()
    for needle in ("not human-written", "gemini-3.8-flash-high", "plsql-lens was not run"):
        assert needle in text, f"README must state: {needle!r}"


def test_every_rule_has_enough_expect_and_clean_markers():
    counts: Counter[tuple[str, str]] = Counter()
    for path in FILES:
        for _, kind, rule, _ in markers(path):
            counts[(kind, rule)] += 1
    short = [
        f"{kind} {rule}: {counts[(kind, rule)]}"
        for rule in RULES
        for kind in ("expect", "clean")
        if counts[(kind, rule)] < 5
    ]
    assert not short, f"need >= 5 expect and >= 5 clean per rule, short on: {short}"


def test_there_are_beyond_markers():
    total = sum(1 for p in FILES for _, kind, _, _ in markers(p) if kind == "beyond")
    assert total >= 5, f"expected >= 5 'beyond' markers, found {total}"


def test_domains_are_neutral_and_varied():
    domains = []
    for path in FILES:
        line = read_lines(path)[1]
        domains.append(line.removeprefix("-- domain: ").strip())
    unknown = sorted(set(domains) - DOMAINS)
    assert not unknown, f"domains outside the allowed neutral list: {unknown}"
    assert len(set(domains)) >= 8, f"need >= 8 distinct domains, found {len(set(domains))}"
    assert max(Counter(domains).values()) <= 6, "no domain may have more than 6 cases"


def test_difficulty_mix():
    levels = Counter(read_lines(p)[2].removeprefix("-- difficulty: ").strip() for p in FILES)
    for level in DIFFICULTIES:
        assert levels[level] >= 5, f"need >= 5 '{level}' cases, found {levels[level]}"


def test_files_are_not_duplicates():
    digests = [hashlib.sha256(p.read_bytes()).hexdigest() for p in FILES]
    assert len(set(digests)) == len(digests), "two cases are byte-identical"


@pytest.mark.parametrize("path", FILES, ids=IDS)
def test_header(path: Path):
    lines = read_lines(path)
    assert lines[0] == f"-- case: {path.stem}"
    assert lines[1].startswith("-- domain: ") and lines[1].removeprefix("-- domain: ").strip()
    assert lines[2].startswith("-- difficulty: ")
    assert lines[2].removeprefix("-- difficulty: ").strip() in DIFFICULTIES
    assert lines[3].startswith("-- note: ") and lines[3].removeprefix("-- note: ").strip()
    assert lines[4] == AUTHOR


@pytest.mark.parametrize("path", FILES, ids=IDS)
def test_shape_of_the_file(path: Path):
    lines = read_lines(path)
    assert 20 <= len(lines) <= 120, f"{len(lines)} lines; must be 20-120"
    body = "\n".join(lines[HEADER_LINES:])
    assert re.search(
        r"^\s*create\s+or\s+replace\s+(package\s+body|procedure|function|trigger)\b",
        body,
        re.IGNORECASE | re.MULTILINE,
    ), "missing CREATE OR REPLACE"
    assert [ln for ln in lines if ln.strip()][-1].strip() == "/", "must end with a '/' line"
    subprograms = re.findall(
        r"^\s*(?:procedure|function)\s+\w+", body, re.IGNORECASE | re.MULTILINE
    )
    assert len(subprograms) >= 2, f"need >= 2 subprograms, found {len(subprograms)}"


@pytest.mark.parametrize("path", FILES, ids=IDS)
def test_no_secrets_urls_or_suppressions(path: Path):
    text = path.read_text(encoding="utf-8")
    assert "plsql-lens: disable" not in text.lower(), "suppression comments hide findings"
    assert "@" not in text and "http" not in text.lower(), "no emails or URLs"


@pytest.mark.parametrize("path", FILES, ids=IDS)
def test_markers_are_well_formed_and_sit_on_code(path: Path):
    for n, line in enumerate(read_lines(path)[HEADER_LINES:], start=HEADER_LINES + 1):
        _, comment = split_comment(line)
        if STRAY_RE.search(comment) and not MARKER_RE.search(comment):
            pytest.fail(f"{path.name}:{n}: looks like a marker but is malformed: {comment.strip()}")
    for n, kind, rule, code in markers(path):
        assert code.strip(), f"{path.name}:{n}: marker {kind}: {rule} must trail a line of code"
        if kind in ("expect", "clean"):
            assert LINE_CHECK[rule].search(code.lower()), (
                f"{path.name}:{n}: {kind}: {rule} sits on a line that cannot be that construct: "
                f"{code.strip()}"
            )


@pytest.mark.parametrize("path", FILES, ids=IDS)
def test_pll007_expects_come_in_groups_of_three_or_more(path: Path):
    n = sum(1 for _, kind, rule, _ in markers(path) if (kind, rule) == ("expect", "PLL007"))
    assert n == 0 or n >= 3, f"{path.name}: PLL007 needs >= 3 occurrences per defect, marked {n}"
