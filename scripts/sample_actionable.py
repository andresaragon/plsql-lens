"""Seeded sample (<= 15 per rule) of findings of the CURRENT rules on the real corpus, for hand labeling.

Usage: python scripts/sample_actionable.py docs/benchmarks/actionable/sample.json
"""

import json
import random
import sys
from pathlib import Path

from plsql_lens.bench.config import repo_root
from plsql_lens.bench.engine import run_engine
from plsql_lens.bench.extras import corpus_files
from plsql_lens.bench.model import RULE_IDS

SEED, PER_RULE = 4004, 15
root = repo_root()
found = sorted({(f.file, f.rule, f.line) for f in run_engine(root, corpus_files(root))})
rng = random.Random(SEED)
sample = {}
for rule in RULE_IDS:
    items = [x for x in found if x[1] == rule]
    sample[rule] = [
        {"file": f, "line": ln} for f, _, ln in sorted(rng.sample(items, min(PER_RULE, len(items))))
    ]
out = Path(sys.argv[1])
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({"seed": SEED, "totals": {r: sum(1 for x in found if x[1] == r) for r in RULE_IDS},
                           "sample": sample}, indent=1) + "\n")  # fmt: skip
print({r: len(v) for r, v in sample.items()})
