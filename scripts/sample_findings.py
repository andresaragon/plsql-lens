"""Deterministic sample (seed 42) of at most N findings per rule over corpus/, held-out excluded."""

import json
import random
import sys
from pathlib import Path

from plsql_lens.inventory import collect_files
from plsql_lens.parser import parse_file
from plsql_lens.rules import RULES, review

ROOT = Path(__file__).resolve().parents[1]
HELDOUT = set(json.loads((ROOT / "tests/heldout/labels.json").read_text()))


def main(out: Path, n: int = 10) -> None:
    by_rule: dict[str, list[dict[str, object]]] = {r: [] for r in RULES}
    for f in collect_files([ROOT / "corpus"]):
        rel = f.relative_to(ROOT).as_posix()
        if rel in HELDOUT:
            continue
        for x in review(parse_file(rel)):
            by_rule[x.rule_id].append(
                {"rule": x.rule_id, "file": rel, "line": x.location.line, "message": x.message}
            )
    rng = random.Random(42)
    sample = {r: rng.sample(v, min(n, len(v))) for r, v in by_rule.items()}
    out.write_text(
        json.dumps({"totals": {r: len(v) for r, v in by_rule.items()}, "sample": sample}, indent=1)
    )


main(Path(sys.argv[1]))
