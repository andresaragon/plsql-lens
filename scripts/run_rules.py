"""Run the review rules of whichever ``plsql_lens`` is first on sys.path over a directory.

Prints a JSON list of [relative_path, rule_id, line]. Used by the benchmark for both the "before"
rules (exported from a git commit, via PYTHONPATH) and the current ones, so both go through the same
code path: ``python scripts/run_rules.py DIR [file ...]``.
"""

import json
import sys
from pathlib import Path

from plsql_lens.parser import parse_file
from plsql_lens.rules import review

root = Path(sys.argv[1]).resolve()
rels = sys.argv[2:] or sorted(
    p.relative_to(root).as_posix()
    for p in root.rglob("*")
    if p.is_file() and p.suffix.lower() in {".pkb", ".pks", ".sql", ".tpb", ".tps", ".trg", ".plb"}
)
out = []
for rel in rels:
    for f in review(parse_file(root / rel)):
        out.append([rel, f.rule_id, f.location.line])
print(json.dumps(out))
