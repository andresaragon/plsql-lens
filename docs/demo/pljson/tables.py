"""Generate and check the numeric blocks of the two sample reports from the raw tool output.

Same as ``docs/demo/oos-utils/tables.py`` plus two blocks: ``inventory`` (units by kind, from
``raw/inventory.json``) and ``compare`` (occurrences per rule here and in ``oos-utils``).

Every count in ``migration-audit.md`` / ``migration-audit.es.md`` sits between BEGIN:name / END:name
HTML-comment markers and comes from ``raw/migrate.json``, ``raw/scope.json`` or
``review.json`` (the manual review). ``--write`` regenerates the blocks, ``--check`` (the default)
fails if a report differs from what the raw files give.

    python docs/demo/pljson/tables.py [--write]
"""

from __future__ import annotations

import collections
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SEVERITIES = ("high", "medium", "low", "info")
PER_RULE = 4  # the review sample: the first PER_RULE findings of each rule by (file, line, column)

LABELS = {
    "en": {
        "metric": "Measure",
        "value": "Value",
        "files": "PL/SQL files analyzed",
        "lines": "Lines in those files",
        "findings": "Findings",
        "with": "Files with at least one finding",
        "rule": "Rule",
        "severity": "Severity",
        "occ": "Occurrences",
        "file": "File",
        "total": "Total",
        "loc": "Location",
        "verdict": "Verdict",
        "reason": "Reason",
        "real": "real hit",
        "doubtful": "doubtful",
        "false_positive": "false positive",
        "sample": "Reviewed sample: {n} findings, {r} real hit, {d} doubtful, {f} false positive.",
        "by_sev": "Findings by severity",
        "kind": "Unit kind in the inventory",
        "units": "Units",
        "project_a": "oos-utils",
        "project_b": "pljson",
        "headline": "PL/SQL Lens (migration rules MIG001–MIG017) reports **{n} findings in {f} of "
        "{t} files**: {h} `high`, {m} `medium`, {lo} `low` (raw output).",
    },
    "es": {
        "metric": "Medida",
        "value": "Valor",
        "files": "Archivos PL/SQL analizados",
        "lines": "Líneas en esos archivos",
        "findings": "Hallazgos",
        "with": "Archivos con al menos un hallazgo",
        "rule": "Regla",
        "severity": "Severidad",
        "occ": "Ocurrencias",
        "file": "Archivo",
        "total": "Total",
        "loc": "Ubicación",
        "verdict": "Veredicto",
        "reason": "Motivo",
        "real": "acierto real",
        "doubtful": "dudoso",
        "false_positive": "falso positivo",
        "sample": "Muestra revisada: {n} hallazgos, {r} aciertos reales, {d} dudosos, "
        "{f} falsos positivos.",
        "by_sev": "Hallazgos por severidad",
        "kind": "Tipo de unidad en el inventario",
        "units": "Unidades",
        "project_a": "oos-utils",
        "project_b": "pljson",
        "headline": "PL/SQL Lens (reglas de migración MIG001–MIG017) reporta **{n} hallazgos "
        "en {f} de {t} archivos**: {h} `high`, {m} `medium`, {lo} `low` (salida cruda).",
    },
}


def load() -> tuple[list[dict], dict, dict]:
    findings = json.loads((HERE / "raw" / "migrate.json").read_text())["findings"]
    scope = json.loads((HERE / "raw" / "scope.json").read_text())
    review = json.loads((HERE / "review.json").read_text())
    return findings, scope, review


def table(header: list[str], rows: list[list[str]]) -> str:
    out = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out += ["| " + " | ".join(r) + " |" for r in rows]
    return "\n".join(out)


def sample_keys(findings: list[dict]) -> list[dict]:
    by_rule: dict[str, list[dict]] = collections.defaultdict(list)
    for f in sorted(findings, key=lambda f: (f["file"], f["line"], f["col"])):
        by_rule[f["rule_id"]].append(f)
    return [f for rid in sorted(by_rule) for f in by_rule[rid][:PER_RULE]]


def blocks(lang: str) -> dict[str, str]:
    t = LABELS[lang]
    findings, scope, review = load()
    sev = collections.Counter(f["severity"] for f in findings)
    nfiles = len({f["file"] for f in findings})
    facts = table(
        [t["metric"], t["value"]],
        [
            [t["files"], str(scope["files"])],
            [t["lines"], str(scope["lines"])],
            [t["findings"], str(len(findings))],
            [t["with"], str(nfiles)],
            *[[f"{t['by_sev']}: `{s}`", str(sev[s])] for s in SEVERITIES if sev[s]],
        ],
    )
    occ: collections.Counter[tuple[str, str]] = collections.Counter()
    files: dict[tuple[str, str], set[str]] = collections.defaultdict(set)
    for f in findings:
        occ[(f["rule_id"], f["severity"])] += 1
        files[(f["rule_id"], f["severity"])].add(f["file"])
    order = sorted(occ, key=lambda k: (k[0], SEVERITIES.index(k[1])))
    by_rule = table(
        [t["rule"], t["severity"], t["occ"], t["file"] + "s"],
        [[r, s, str(occ[(r, s)]), str(len(files[(r, s)]))] for r, s in order],
    )
    per_file = collections.Counter(f["file"] for f in findings)
    top = sorted(per_file.items(), key=lambda kv: (-kv[1], kv[0]))[:10]
    by_file = table(
        [t["file"], t["findings"]],
        [[f"`{p}`", str(n)] for p, n in top]
        + [[f"**{t['total']}** ({len(per_file)})", str(len(findings))]],
    )
    keys = sample_keys(findings)
    reviewed = {(i["file"], i["line"], i["col"]): i for i in review["items"]}
    rows, count = [], collections.Counter()
    for n, f in enumerate(keys, 1):
        item = reviewed[(f["file"], f["line"], f["col"])]
        assert item["rule"] == f["rule_id"], item
        count[item["verdict"]] += 1
        rows.append(
            [
                str(n),
                f["rule_id"],
                f["severity"],
                f"`{f['file']}:{f['line']}`",
                t[item["verdict"]],
                item[lang],
            ]
        )
    assert set(reviewed) == {(f["file"], f["line"], f["col"]) for f in keys}, (
        "review.json != sample"
    )
    sample = table(["#", t["rule"], t["severity"], t["loc"], t["verdict"], t["reason"]], rows)
    totals = t["sample"].format(
        n=len(keys), r=count["real"], d=count["doubtful"], f=count["false_positive"]
    )
    inv = json.loads((HERE / "raw" / "inventory.json").read_text())
    kinds = collections.Counter(u["kind"] for u in inv["units"])
    inventory = table(
        [t["kind"], t["units"]],
        [[f"`{k}`", str(kinds[k])] for k in sorted(kinds)]
        + [[f"**{t['total']}**", str(len(inv["units"]))]],
    )
    other = json.loads((HERE.parent / "oos-utils" / "raw" / "migrate.json").read_text())["findings"]
    here_n = collections.Counter(f["rule_id"] for f in findings)
    other_n = collections.Counter(f["rule_id"] for f in other)
    compare = table(
        [t["rule"], t["project_a"], t["project_b"]],
        [[r, str(other_n[r]), str(here_n[r])] for r in sorted(set(here_n) | set(other_n))]
        + [[f"**{t['total']}**", f"**{len(other)}**", f"**{len(findings)}**"]],
    )
    return {
        "facts": facts,
        "inventory": inventory,
        "compare": compare,
        "headline": t["headline"].format(
            n=len(findings),
            f=nfiles,
            t=scope["files"],
            h=sev["high"],
            m=sev["medium"],
            lo=sev["low"],
        ),
        "by_rule": by_rule,
        "by_file": by_file,
        "sample": sample,
        "sample_totals": totals,
    }


def render(text: str, new: dict[str, str]) -> str:
    for name, body in new.items():
        pat = re.compile(rf"(<!-- BEGIN:{name} -->\n).*?(\n<!-- END:{name} -->)", re.DOTALL)
        if not pat.search(text):
            raise SystemExit(f"block {name!r} missing")
        text = pat.sub(lambda m, b=body: m.group(1) + b + m.group(2), text)
    return text


def main(argv: list[str]) -> int:
    write = "--write" in argv
    bad = 0
    for lang, name in (("en", "migration-audit.md"), ("es", "migration-audit.es.md")):
        path = HERE / name
        old = path.read_text()
        new = render(old, blocks(lang))
        if new != old:
            if write:
                path.write_text(new)
                print(f"updated {name}")
            else:
                print(f"{name} does not match the raw output (run with --write)")
                bad = 1
        else:
            print(f"{name}: ok")
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
