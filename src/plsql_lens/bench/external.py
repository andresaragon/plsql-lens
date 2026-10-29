"""External-author split (F4b): marker converter, strict evaluator, adjudication, tables.

Cases carry trailing ``-- expect: PLLnnn`` / ``-- clean: PLLnnn`` / ``-- beyond: PLLnnn`` markers.
The converter strips the markers and the descriptive header (line numbers are preserved) and records
what they said in a manifest; the evaluator scores findings against it. Everything not marked is
assumed clean, so the **strict** table counts any finding on an unmarked line as a false positive.
The **adjudicated** table applies per-finding decisions on top, without touching the strict one.
"""

from __future__ import annotations

import hashlib
import json
import re
from collections.abc import Iterable
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from ..parser import Subprogram, parse_source
from .model import RULE_IDS, Found
from .stats import prf

MARKER = re.compile(r"\b(expect|beyond|clean):\s*(PLL00[1-7])\b")
_HEADER = re.compile(r"^--\s*(case|domain|difficulty|note|author):\s*(.*)$")
HEADER_LINES = 6


@dataclass
class Case:
    id: str
    file: str
    domain: str = ""
    difficulty: str = ""
    expect: dict[str, list[int]] = field(default_factory=dict)
    beyond: dict[str, list[int]] = field(default_factory=dict)
    clean: dict[str, list[dict[str, int]]] = field(
        default_factory=dict
    )  # rule -> [{line,start,end}]


@dataclass
class ExternalManifest:
    cases: list[Case]
    sha256: dict[str, str] = field(default_factory=dict)  # clean file -> hash
    source_sha256: dict[str, str] = field(default_factory=dict)  # original (marked) file -> hash

    def to_dict(self) -> dict[str, Any]:
        return {
            "cases": [
                {
                    "id": c.id,
                    "file": c.file,
                    "domain": c.domain,
                    "difficulty": c.difficulty,
                    "expect": dict(sorted(c.expect.items())),
                    "beyond": dict(sorted(c.beyond.items())),
                    "clean": dict(sorted(c.clean.items())),
                }  # fmt: skip
                for c in self.cases
            ],
            "sha256": dict(sorted(self.sha256.items())),
            "source_sha256": dict(sorted(self.source_sha256.items())),
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> ExternalManifest:
        cases = [Case(**c) for c in d["cases"]]
        return cls(cases, d.get("sha256", {}), d.get("source_sha256", {}))

    @classmethod
    def load(cls, path: Path) -> ExternalManifest:
        return cls.from_dict(json.loads(path.read_text()))


def manifest_hash(m: ExternalManifest) -> str:
    return hashlib.sha256(
        json.dumps(m.to_dict(), sort_keys=True, separators=(",", ":")).encode()
    ).hexdigest()


def _comment_start(line: str) -> int | None:
    """Index of the first ``--`` outside a single-quoted string, or None."""
    in_str = False
    i = 0
    while i < len(line):
        ch = line[i]
        if ch == "'":
            in_str = not in_str
        elif not in_str and line.startswith("--", i):
            return i
        i += 1
    return None


def _strip_markers(line: str) -> tuple[str, list[tuple[str, str]]]:
    start = _comment_start(line)
    if start is None:
        return line, []
    marks = MARKER.findall(line[start:])
    if not marks:
        return line, []
    return line[:start].rstrip(), marks


def convert(cases_dir: Path, out_dir: Path) -> ExternalManifest:
    """Write marker-free copies of ``cases_dir/*.pkb`` under ``out_dir`` plus ``manifest.json``."""
    out_dir.mkdir(parents=True, exist_ok=True)
    cases: list[Case] = []
    sha: dict[str, str] = {}
    src_sha: dict[str, str] = {}
    for path in sorted(cases_dir.glob("*.pkb")):
        raw = path.read_bytes()
        src_sha[path.name] = hashlib.sha256(raw).hexdigest()
        case = Case(id=path.stem, file=path.name)
        lines = raw.decode().split("\n")
        if lines and lines[-1] == "":
            lines.pop()
        clean_lines: list[str] = []
        marks_at: list[tuple[int, str, str]] = []
        for n, line in enumerate(lines, 1):
            h = _HEADER.match(line.strip()) if n <= HEADER_LINES else None
            if h:
                if h.group(1) == "case":
                    case.id = h.group(2).strip() or path.stem
                elif h.group(1) in ("domain", "difficulty"):
                    setattr(case, h.group(1), h.group(2).strip())
                clean_lines.append("")
                continue
            stripped, marks = _strip_markers(line)
            clean_lines.append(stripped)
            marks_at.extend((n, kind, rule) for kind, rule in marks)
        text = "\n".join(clean_lines) + "\n"
        spans = _subprogram_spans(parse_source(text, path.name))
        for n, kind, rule in marks_at:
            if kind == "expect":
                case.expect.setdefault(rule, []).append(n)
            elif kind == "beyond":
                case.beyond.setdefault(rule, []).append(n)
            else:
                start, end = _enclosing(spans, n)
                case.clean.setdefault(rule, []).append({"line": n, "start": start, "end": end})
        (out_dir / path.name).write_text(text)
        sha[path.name] = hashlib.sha256(text.encode()).hexdigest()
        cases.append(case)
    m = ExternalManifest(cases, sha, src_sha)
    (out_dir / "manifest.json").write_text(json.dumps(m.to_dict(), indent=1, sort_keys=True) + "\n")
    return m


def _subprogram_spans(ir: Any) -> list[tuple[int, int]]:
    spans: list[tuple[int, int]] = []

    def walk(sp: Subprogram) -> None:
        if sp.end_line:
            spans.append((sp.line, sp.end_line))
        for n in sp.nested:
            walk(n)

    for u in ir.units:
        if u.end_line and u.kind not in ("package", "package_body"):
            spans.append((u.line, u.end_line))
        for sp in u.subprograms:
            walk(sp)
    return spans


def _enclosing(spans: list[tuple[int, int]], line: int) -> tuple[int, int]:
    inside = [s for s in spans if s[0] <= line <= s[1]]
    return min(inside, key=lambda s: s[1] - s[0]) if inside else (line, line)


# ---- evaluation ---------------------------------------------------------------------------


@dataclass
class ExternalScore:
    per_rule: dict[str, dict[str, int]]
    beyond: dict[str, dict[str, int]]
    unmarked: list[dict[str, Any]]  # findings on unmarked lines (strict FPs), to adjudicate
    missed: list[dict[str, Any]]  # expect markers nobody reported (strict FNs), to adjudicate


def evaluate(m: ExternalManifest, findings: Iterable[Found]) -> ExternalScore:
    per = {r: {"tp": 0, "fp": 0, "fn": 0, "fp_in_clean": 0} for r in RULE_IDS}
    beyond = {r: {"hit": 0, "total": 0} for r in RULE_IDS}
    unmarked: list[dict[str, Any]] = []
    missed: list[dict[str, Any]] = []
    found = {(f.file, f.rule, f.line) for f in findings}
    by_file = {c.file: c for c in m.cases}
    for file, rule, line in sorted(found):
        c = by_file.get(file)
        if c is None or rule not in per:
            continue
        if line in c.expect.get(rule, ()):
            per[rule]["tp"] += 1
        elif line in c.beyond.get(rule, ()):
            beyond[rule]["hit"] += 1
        else:
            in_clean = any(r["start"] <= line <= r["end"] for r in c.clean.get(rule, ()))
            per[rule]["fp"] += 1
            per[rule]["fp_in_clean"] += in_clean
            unmarked.append({"file": file, "rule": rule, "line": line, "in_clean": in_clean})
    for c in m.cases:
        for rule, lines in c.expect.items():
            for ln in lines:
                if (c.file, rule, ln) not in found:
                    per[rule]["fn"] += 1
                    missed.append({"file": c.file, "rule": rule, "line": ln})
        for rule, lines in c.beyond.items():
            beyond[rule]["total"] += len(lines)
    unmarked.sort(key=lambda u: (u["file"], u["rule"], u["line"]))
    missed.sort(key=lambda u: (u["file"], u["rule"], u["line"]))
    return ExternalScore(per, beyond, unmarked, missed)


def apply_adjudication(
    score: ExternalScore, decisions: Iterable[dict[str, Any]]
) -> dict[str, dict[str, int]]:
    """Counts after the decisions; the strict ``score`` is not modified.

    ``unmarked_finding`` + ``real_defect``: the author missed a marker, the finding becomes a TP.
    ``missed_expect`` + ``marker_wrong``: the marker was wrong, the FN disappears.
    Everything else (including findings with no decision) keeps its strict classification.
    """
    adj = {
        r: {k: v for k, v in c.items() if k in ("tp", "fp", "fn")}
        for r, c in score.per_rule.items()
    }
    unmarked = {(u["file"], u["rule"], u["line"]) for u in score.unmarked}
    missed = {(u["file"], u["rule"], u["line"]) for u in score.missed}
    for d in decisions:
        key = (d["file"], d["rule"], d["line"])
        if d["kind"] == "unmarked_finding" and d["verdict"] == "real_defect" and key in unmarked:
            adj[d["rule"]]["tp"] += 1
            adj[d["rule"]]["fp"] -= 1
        elif d["kind"] == "missed_expect" and d["verdict"] == "marker_wrong" and key in missed:
            adj[d["rule"]]["fn"] -= 1
    return adj


def _cell(p: dict[str, Any], key: str) -> str:
    v, ci = p.get(key), p.get(f"{key}_ci")
    return "n/a" if v is None or ci is None else f"{v:.3f} [{ci[0]:.2f}–{ci[1]:.2f}]"


def _table(counts: dict[str, dict[str, int]], extra: dict[str, str] | None = None) -> list[str]:
    head = "| Rule | TP | FP | FN | Precision | Recall | F1 |" + (
        " FP in a `clean` trap |" if extra else ""
    )
    lines = [head, "|---|---|---|---|---|---|---|" + ("---|" if extra else "")]
    tot = {"tp": 0, "fp": 0, "fn": 0}
    for r in (*RULE_IDS, "all"):
        c = tot if r == "all" else counts[r]
        if r != "all":
            for k in tot:
                tot[k] += c[k]
        p = prf(c["tp"], c["fp"], c["fn"])
        row = f"| {'**all**' if r == 'all' else r} | {c['tp']} | {c['fp']} | {c['fn']} | {_cell(p, 'precision')} | {_cell(p, 'recall')} | {_cell(p, 'f1')} |"
        if extra:
            row += f" {extra.get(r, '')} |"
        lines.append(row)
    return lines


def render_tables(
    title: str,
    score: ExternalScore,
    adjudicated: dict[str, dict[str, int]],
    provisional: bool = True,
) -> str:
    traps = {r: str(c["fp_in_clean"]) for r, c in score.per_rule.items()}
    traps["all"] = str(sum(c["fp_in_clean"] for c in score.per_rule.values()))
    out = [
        f"### {title}",
        "",
        "**Strict** (every finding on an unmarked line is a false positive)",
        "",
    ]
    out += _table(score.per_rule, traps)
    label = " — *provisional (Claude), pending your review*" if provisional else ""
    out += ["", f"**Adjudicated**{label}", ""]
    out += _table(adjudicated)
    hit = sum(b["hit"] for b in score.beyond.values())
    tot = sum(b["total"] for b in score.beyond.values())
    out += [
        "",
        f"**Real-world (`beyond`) recall**: {hit} of {tot} markers reported (reported apart, not in the tables above).",
        "",
    ]
    return "\n".join(out)
