"""Severity by context for MIG011 and MIG002 (F5-G3, docs/migration-rules.md "Severity by context").

Written from the contract. The corpus checks compare the findings with the F5c adjudication, which
is a consistency check (19 findings, adjudicated provisionally by Claude), not an independent test:
the context definitions come from the verified semantics, not from the counts.
"""

from __future__ import annotations

import collections
import json
import re
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator
from typer.testing import CliRunner

from plsql_lens.cli import app
from plsql_lens.inventory import collect_files
from plsql_lens.migrate import MIGRATION_RULES, migrate_file, migrate_source
from plsql_lens.migrate.output import to_json, to_sarif, to_table

ROOT = Path(__file__).resolve().parents[2]
ADJ = json.loads((ROOT / "docs" / "reports" / "phase-5" / "adjudication.json").read_text())
SCHEMA = json.loads((ROOT / "tests" / "vendor" / "sarif-2.1.0.json").read_text())
run = CliRunner().invoke


def sev(src: str, rule: str) -> list[str]:
    return [f.severity for f in migrate_source(src, "x.sql", [rule])]


# --- the rule's severity is the maximum --------------------------------------------------------


def test_rule_severity_is_the_highest_a_finding_can_have() -> None:
    assert MIGRATION_RULES["MIG011"].severity == "high"
    assert MIGRATION_RULES["MIG002"].severity == "medium"


# --- MIG011 ------------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("src", "expected"),
    [
        ("x := a || '';", ["info"]),
        ("x := '' || a;", ["info"]),
        ("x := a || '' || b;", ["info"]),
        ("x := a ||\n  '';", ["info"]),
        ("x := a || /* c */ '';", ["info"]),
        ("x := a || n'';", ["info"]),
        ("x := replace(a, 'b', '');", ["medium"]),
        ("x := REPLACE(a, 'b', '');", ["medium"]),
        ("x := regexp_replace(a, 'b', '');", ["medium"]),
        ("x := regexp_replace(a, 'b', '', 1, 0, 'i');", ["medium"]),
        ("x := regexp_replace(trim(a), f(1, 2), '');", ["medium"]),
        ("x := replace(a, 'b', n'');", ["medium"]),
        ("x := '';", ["high"]),
        ("x := n'';", ["high"]),
        ("IF a = '' THEN null; END IF;", ["high"]),
        ("x := replace(a, '', 'c');", ["high"]),  # the search, not the replacement
        ("x := replace('', 'b', 'c');", ["high"]),  # the source string
        ("x := replace(a, '');", ["high"]),  # two arguments: it is the 2nd
        ("x := regexp_replace(a, 'b', ('') );", ["high"]),  # not the whole argument
        ("x := pkg.replace(a, 'b', '');", ["high"]),  # a user's replace
        ("x := translate(a, 'b', '');", ["high"]),
        ("x := nvl(replace(a, 'b', 'c'), '');", ["high"]),
        ("x := replace(a, 'b', '' || 'c');", ["info"]),  # next to `||` wins
        ("x := replace(a, 'b', 'c' || '');", ["info"]),
        ("x := a || ''; y := ''; z := replace(a, 'b', '');", ["info", "high", "medium"]),
    ],
)
def test_mig011_severity_by_context(src: str, expected: list[str]) -> None:
    assert sev(src, "MIG011") == expected


def test_the_number_and_location_of_mig011_findings_do_not_depend_on_severity() -> None:
    src = "a := '' || b;\nc := replace(d, 'e', '');\nf := '';\n"
    findings = migrate_source(src, "x.sql", ["MIG011"])
    assert [(f.location.line, f.location.col) for f in findings] == [(1, 6), (2, 22), (3, 6)]


# --- MIG002 ------------------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("src", "expected"),
    [
        ("x := decode(a, 1, 'x', 2, 'y', 'z');", ["low"]),
        ("x := decode(a, 'k', 1);", ["low"]),
        ("x := decode(a, -1, 'n', +2, 'p');", ["low"]),
        ("x := decode(a, - 1, 'n');", ["low"]),
        ("x := decode(a, 1, b, 2, c, d);", ["low"]),  # columns as results or default
        ("x := decode(a, 1, 'x', NULL);", ["low"]),  # NULL as the default
        ("x := decode(a, 1, NULL, 'z');", ["low"]),  # NULL as a result
        ("x := decode(a, b, 1, 0);", ["medium"]),
        ("x := decode(t.a, t.b, 1, 0);", ["medium"]),
        ("x := decode(a, 1, 'x', b, 'y', 'z');", ["medium"]),  # one non-literal search is enough
        ("x := decode(a, NULL, 'x', 'y');", ["medium"]),
        ("x := decode(a, 1 + 1, 'x');", ["medium"]),
        ("x := decode(a, f(1), 'x');", ["medium"]),
        ("x := decode(a, -b, 'x');", ["medium"]),
        ("x := decode(a, 'k' || 'l', 'x');", ["medium"]),
        ("x := decode(a, 1, decode(b, c, 1, 0), 'z');", ["low", "medium"]),
    ],
)
def test_mig002_severity_by_search_values(src: str, expected: list[str]) -> None:
    # nested calls come out in source order: the outer DECODE first
    assert sev(src, "MIG002") == expected


def test_a_medium_mig002_message_explains_the_null_matching() -> None:
    (f,) = migrate_source("x := decode(a, b, 1, 0);", "x.sql", ["MIG002"])
    assert f.severity == "medium"
    assert "NULL" in f.message and "columns" in f.message and "CASE" in f.message
    (g,) = migrate_source("x := decode(a, NULL, 1, 0);", "x.sql", ["MIG002"])
    assert g.severity == "medium" and "NULL" in g.message and "columns" in g.message


def test_a_low_mig002_message_is_unchanged_and_has_no_null_warning() -> None:
    (f,) = migrate_source("x := decode(a, 'k', 1, 0);", "x.sql", ["MIG002"])
    assert f.severity == "low" and f.message == "Oracle DECODE() call"


# --- the outputs use the severity of each finding ----------------------------------------------


MIXED = (
    "x := '' || a;\ny := replace(a, 'b', '');\nz := '';\n"
    "w := decode(a, 1, 2);\nv := decode(a, b, 1);\n"
)


def test_table_and_json_show_each_findings_own_severity() -> None:
    findings = migrate_source(MIXED, "x.sql", ["MIG002", "MIG011"])
    assert [f.severity for f in findings] == ["info", "medium", "high", "low", "medium"]
    table = to_table(findings)
    assert [ln.split()[0] for ln in table.splitlines()[2:]] == [
        "INFO",
        "MEDIUM",
        "HIGH",
        "LOW",
        "MEDIUM",
    ]
    doc = json.loads(to_json(findings))["findings"]
    assert [d["severity"] for d in doc] == ["info", "medium", "high", "low", "medium"]


def test_sarif_level_is_per_result_and_validates() -> None:
    findings = migrate_source(MIXED, "x.sql", ["MIG002", "MIG011"])
    doc = json.loads(to_sarif(findings))
    assert [e.message for e in Draft202012Validator(SCHEMA).iter_errors(doc)] == []
    run0 = doc["runs"][0]
    assert [r["level"] for r in run0["results"]] == ["note", "warning", "error", "note", "warning"]
    rules = {r["id"]: r for r in run0["tool"]["driver"]["rules"]}
    assert rules["MIG011"]["defaultConfiguration"]["level"] == "error"
    assert rules["MIG002"]["defaultConfiguration"]["level"] == "warning"


# --- --fail-on uses the severity of the finding ------------------------------------------------


def test_fail_on_high_on_the_corpus_for_mig011_exits_1() -> None:
    res = run(app, ["migrate", str(ROOT / "corpus"), "--rules", "MIG011", "--fail-on", "high"])
    assert res.exit_code == 1


def test_a_file_with_only_a_concatenation_does_not_fail_on_medium(tmp_path: Path) -> None:
    f = tmp_path / "only_concat.pkb"
    f.write_text(
        "CREATE OR REPLACE PROCEDURE p(x IN VARCHAR2) IS\n  y VARCHAR2(10);\n"
        "BEGIN\n  y := x || '';\nEND p;\n/\n"
    )
    assert run(app, ["migrate", str(f), "--fail-on", "medium"]).exit_code == 0
    assert run(app, ["migrate", str(f), "--fail-on", "low"]).exit_code == 0
    assert run(app, ["migrate", str(f), "--fail-on", "info"]).exit_code == 1
    res = run(app, ["migrate", str(f), "--format", "json"])
    assert [d["severity"] for d in json.loads(res.output)["findings"]] == ["info"]


def test_a_low_decode_does_not_fail_on_medium_but_a_medium_one_does(tmp_path: Path) -> None:
    low, med = tmp_path / "low.sql", tmp_path / "med.sql"
    low.write_text("select decode(a, 1, 'x', 'y') from t;\n")
    med.write_text("select decode(a, b, 1, 0) from t;\n")
    assert (
        run(app, ["migrate", str(low), "--rules", "MIG002", "--fail-on", "medium"]).exit_code == 0
    )
    assert run(app, ["migrate", str(low), "--rules", "MIG002", "--fail-on", "low"]).exit_code == 1
    assert (
        run(app, ["migrate", str(med), "--rules", "MIG002", "--fail-on", "medium"]).exit_code == 1
    )
    assert run(app, ["migrate", str(med), "--rules", "MIG002", "--fail-on", "high"]).exit_code == 0


# --- the corpus, and the adjudication ----------------------------------------------------------


def _corpus() -> dict[tuple[str, int, int], tuple[str, str]]:
    out: dict[tuple[str, int, int], tuple[str, str]] = {}
    for path in collect_files([ROOT / "corpus"]):
        for f in migrate_file(path):
            rel = Path(f.location.path).resolve().relative_to(ROOT).as_posix()
            out[(rel, f.location.line, f.location.col)] = (f.rule_id, f.severity)
    return out


CORPUS = _corpus()


def _counts(rule: str) -> dict[str, int]:
    return dict(collections.Counter(s for r, s in CORPUS.values() if r == rule))


def test_corpus_mig011_is_2_info_4_medium_2_high() -> None:
    assert _counts("MIG011") == {"info": 2, "medium": 4, "high": 2}


def test_corpus_mig002_is_3_low_8_medium() -> None:
    assert _counts("MIG002") == {"low": 3, "medium": 8}


def _expected_from_adjudication(it: dict[str, str]) -> str:
    if it["rule"] == "MIG011":
        if it["impact"] == "benign":
            return "info"
        return "medium" if it["note"].startswith("'' as the replacement") else "high"
    return {"mechanical": "low", "semantic-trap": "medium"}[it["impact"]]


def test_every_adjudicated_mig011_and_mig002_finding_gets_the_matching_severity() -> None:
    items = [i for i in ADJ["items"] if i["rule"] in ("MIG011", "MIG002")]
    assert len(items) == 19
    mismatches = []
    for it in items:
        rule, got = CORPUS[(it["file"], it["line"], it["col"])]
        assert rule == it["rule"]
        if got != _expected_from_adjudication(it):
            mismatches.append(
                (it["file"], it["line"], it["col"], got, _expected_from_adjudication(it))
            )
    assert mismatches == []


def test_the_report_counts_match_a_fresh_run() -> None:
    rows = re.findall(
        r"^\| (MIG\d{3}) \| (info|low|medium|high) \| (\d+) \| (\d+) \|$",
        (ROOT / "docs" / "reports" / "migrate-severity.md").read_text(),
        flags=re.MULTILINE,
    )
    occurrences: collections.Counter[tuple[str, str]] = collections.Counter()
    files: collections.defaultdict[tuple[str, str], set[str]] = collections.defaultdict(set)
    for (path, _line, _col), (rule, severity) in CORPUS.items():
        occurrences[(rule, severity)] += 1
        files[(rule, severity)].add(path)
    reported = {(r, s): (int(o), int(f)) for r, s, o, f in rows}
    assert reported == {k: (occurrences[k], len(files[k])) for k in occurrences}
