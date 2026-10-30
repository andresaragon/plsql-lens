"""Robustness of the parser against corrupted PL/SQL (issue #16).

README claim under test: the parser "never raises on unknown syntax". Seed files from ``corpus/``
and ``tests/fixtures`` are mutated (truncated, tokens deleted or duplicated, unclosed quote or
``/*`` inserted, case changed, CRLF, BOM) with a fixed seed. For every mutation ``parse_file`` must
not raise, must finish in under 2 s and must return a ``FileIR``, and ``review`` on that IR must not
raise either. A hang counts as a failure, like an exception.

Run: ``uv run pytest tests/robustness -m robustness`` (never part of the default run).
"""

from __future__ import annotations

import collections
import json
import os
import time

import pytest
from hypothesis import HealthCheck, given, settings
from hypothesis import strategies as st
from mutate import (
    MIN_MUTATIONS,
    MUTATIONS,
    OPERATORS,
    PARSE_LIMIT_S,
    ROOT,
    SEED,
    generate_mutations,
    have_time_limit,
    known_signatures,
    run_guarded,
    source_files,
)

pytestmark = [
    pytest.mark.robustness,
    pytest.mark.skipif(not have_time_limit(), reason="needs signal.setitimer (Linux/macOS)"),
]


def _fingerprint(seed: int, count: int) -> list[tuple[str, str, str]]:
    return [(m.source, m.operator, m.digest) for m in generate_mutations(seed, count)]


def test_same_seed_gives_the_exact_same_mutation_list() -> None:
    first = _fingerprint(SEED, 300)
    assert first == _fingerprint(SEED, 300)
    assert first != _fingerprint(SEED + 1, 300)


def test_the_list_is_a_prefix_stable_function_of_the_seed() -> None:
    assert _fingerprint(SEED, 100) == _fingerprint(SEED, 300)[:100]


def test_at_least_2000_mutations_covering_every_operator_and_many_files() -> None:
    assert MUTATIONS >= MIN_MUTATIONS >= 2000
    mutations = list(generate_mutations(SEED, MUTATIONS))
    assert len(mutations) == MUTATIONS
    assert {m.operator for m in mutations} == set(OPERATORS)
    assert len({m.source for m in mutations}) >= 100
    roots = {s.split("/")[0] for s in (m.source for m in mutations)}
    assert roots == {"corpus", "tests"}


def test_seed_files_exist_in_the_repository() -> None:
    files = source_files()
    assert len(files) >= 100
    assert any(f.startswith("corpus/") for f in files)
    assert any(f.startswith("tests/fixtures/") for f in files)


def test_the_guard_reports_a_hang_as_a_failure() -> None:
    out = run_guarded(b"x", parse=lambda _p: time.sleep(5), limit_s=0.2)
    assert not out.ok
    assert out.stage == "parse"
    assert out.error.startswith("Hang")


def test_the_guard_reports_an_exception_as_a_failure() -> None:
    def boom(_path: object) -> object:
        raise ValueError("boom")

    out = run_guarded(b"x", parse=boom)
    assert not out.ok
    assert out.stage == "parse"
    assert out.error.startswith("ValueError")


def test_the_guard_rejects_a_non_fileir_result() -> None:
    out = run_guarded(b"x", parse=lambda _p: 42)
    assert not out.ok
    assert "FileIR" in out.error


def test_parse_and_review_never_raise_nor_hang_on_mutated_sources() -> None:
    started = time.perf_counter()
    outcomes = [(m, run_guarded(m.data)) for m in generate_mutations(SEED, MUTATIONS)]
    total = time.perf_counter() - started

    by_signature: dict[str, list[str]] = collections.defaultdict(list)
    for m, out in outcomes:
        if not out.ok:
            by_signature[out.signature].append(f"{m.source} [{m.operator}]")
    slowest = max(outcomes, key=lambda mo: mo[1].parse_s)
    stats = {
        "seed": SEED,
        "mutations": len(outcomes),
        "total_s": round(total, 2),
        "max_parse_s": round(slowest[1].parse_s, 4),
        "max_parse_source": slowest[0].source,
        "max_review_s": round(max(o.review_s for _, o in outcomes), 4),
        "failure_signatures": {k: len(v) for k, v in sorted(by_signature.items())},
    }
    print("ROBUSTNESS_STATS " + json.dumps(stats, sort_keys=True))
    if path := os.environ.get("ROBUSTNESS_STATS"):
        with open(path, "w") as fh:
            json.dump(stats, fh, indent=2, sort_keys=True)

    assert len(outcomes) >= MIN_MUTATIONS
    assert slowest[1].parse_s < PARSE_LIMIT_S
    unexpected = {k: v[:3] for k, v in by_signature.items() if k not in KNOWN_FINDINGS}
    assert not unexpected, f"new robustness failures (first 3 each): {unexpected}"


# Failure signatures already recorded in docs/reports/robustness.md, each with a minimized
# reproduction under tests/robustness/findings/ and a strict xfail test in test_findings.py.
KNOWN_FINDINGS = known_signatures()


@settings(
    derandomize=True,
    max_examples=300,
    deadline=None,
    database=None,
    suppress_health_check=[HealthCheck.too_slow, HealthCheck.data_too_large],
)
@given(
    data=st.data(),
    snippet=st.text(alphabet=st.characters(blacklist_categories=("Cs",)), max_size=40),
)
def test_arbitrary_truncation_and_insertion_never_break_the_parser(
    data: st.DataObject, snippet: str
) -> None:
    files = source_files()
    name = data.draw(st.sampled_from(files[:: max(1, len(files) // 25)]))
    text = (ROOT / name).read_bytes().decode("utf-8", errors="replace")
    cut = data.draw(st.integers(0, len(text)))
    at = data.draw(st.integers(0, cut))
    mutated = (text[:at] + snippet + text[at:cut]).encode("utf-8")
    out = run_guarded(mutated)
    assert out.ok, f"{name}: {out.signature}"
