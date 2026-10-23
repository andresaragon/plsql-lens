"""Measure per-call overhead of `claude -p` with and without the lean flags (costs cents)."""

import json
import sys
from pathlib import Path

from plsql_lens.llm import ClaudeCliProvider
from plsql_lens.testgen import build_generation_prompt, load_manifest

ROOT = Path.cwd()
IDS = sys.argv[1:] or ["pkg_calc_clamp", "pkg_orders_add_item"]
targets = {t.id: t for t in load_manifest(ROOT / "tests/fixtures/testgen/manifest.json")}
rows = []
for tid in IDS:
    prompt = build_generation_prompt(targets[tid], ROOT)
    for lean in (False, True):
        r = ClaudeCliProvider("claude-sonnet-5-5", lean=lean).complete(prompt)
        rows.append(
            {
                "target": tid,
                "lean": lean,
                "prompt_chars": len(prompt),
                "input_tokens": r.input_tokens,
                "output_tokens": r.output_tokens,
                "cost_usd": r.cost_usd,
                "model": r.model,
            }
        )
        print(rows[-1], flush=True)
Path("docs/reports/phase-3-cli-overhead.json").write_text(json.dumps(rows, indent=1))
