"""Count findings per rule over corpus/ (held-out reserve files excluded)."""

import json
import sys
from collections import Counter
from pathlib import Path

from plsql_lens.inventory import collect_files
from plsql_lens.parser import parse_file
from plsql_lens.rules import RULES, review

ROOT = Path(__file__).resolve().parents[1]
HELDOUT = set(json.loads((ROOT / "tests/heldout/labels.json").read_text()))


def main(out: Path) -> None:
    per_rule: Counter[str] = Counter()
    files = 0
    for f in collect_files([ROOT / "corpus"]):
        rel = f.relative_to(ROOT).as_posix()
        if rel in HELDOUT:
            continue
        files += 1
        per_rule.update(x.rule_id for x in review(parse_file(rel)))
    lines = [f"# Findings per rule over corpus/ ({files} files; held-out reserve excluded)", ""]
    lines += ["| Rule | Severity | Findings |", "|---|---|---|"]
    for rid in sorted(RULES):
        lines.append(f"| {rid} | {RULES[rid].severity} | {per_rule[rid]} |")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


if __name__ == "__main__":
    main(Path(sys.argv[1]))
