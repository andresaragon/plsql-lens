"""The F5 reference cases are Oracle-observed data, pinned by hash."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

FIXTURE = Path(__file__).resolve().parents[1] / "fixtures" / "migrate" / "semantics.json"
SHA256 = "0be583169f722ba22526aff013b97cfec3b32661f117193aab7be5b6df46d318"
CONSTRUCTS = {"nvl", "decode", "nextval", "from_dual", "mixed"}
DIVERGENCES = {"oracle_empty_string_is_null", "oracle_concat_ignores_null"}


def _cases() -> list[dict[str, object]]:
    return list(json.loads(FIXTURE.read_text())["cases"])


def test_fixture_is_the_one_generated_from_oracle() -> None:
    assert hashlib.sha256(FIXTURE.read_bytes()).hexdigest() == SHA256, (
        "semantics.json changed: regenerate it with scripts/migrate_semantics.py"
    )


def test_cases_are_well_formed() -> None:
    cases = _cases()
    assert len(cases) == 42
    assert len({c["id"] for c in cases}) == len(cases)
    for c in cases:
        assert c["construct"] in CONSTRUCTS
        assert str(c["oracle_sql"]).lstrip().upper().startswith("SELECT")
        assert isinstance(c["setup"], list)
        assert str(c["oracle_result"]) and "Oracle" in str(c["oracle_version"])


def test_divergences_are_labelled_with_a_known_reason_and_differ_from_oracle() -> None:
    diverging = [c for c in _cases() if "known_divergence" in c]
    assert len(diverging) == 5
    for c in diverging:
        kd = c["known_divergence"]
        assert isinstance(kd, dict)
        assert kd["reason"] in DIVERGENCES
        assert kd["pg_naive_result"] != c["oracle_result"]
