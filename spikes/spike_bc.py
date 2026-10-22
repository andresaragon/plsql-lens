"""Options B (tree-sitter 'sql' grammar via tree-sitter-language-pack) and C (sqlglot, Oracle dialect).

Usage: python spike_bc.py OUT.json
Success: B = parse tree has no ERROR/MISSING node; C = sqlglot.parse(read="oracle") raises no exception
(sqlglot falls back to opaque Command nodes for what it cannot parse; those are counted separately).
Neither tool offers a PL/SQL grammar, so no unit/edge inventory is attempted for them.
"""

import json, sys, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTS = {".pks", ".pkb", ".tps", ".tpb", ".trg", ".plb", ".sql"}
files = sorted(p for p in (ROOT / "corpus").rglob("*") if p.suffix in EXTS)
out = {}

import tree_sitter_language_pack as tsp

parser = tsp.get_parser("sql")


def has_err(node):
    stack = [node]
    while stack:
        n = stack.pop()
        if n.is_error or n.is_missing:
            return True
        stack.extend(n.children)
    return False


res, tot_s, tot_l = [], 0.0, 0
for f in files:
    b = f.read_bytes()
    lines = b.count(b"\n") + 1
    t0 = time.perf_counter()
    tree = parser.parse(b)
    dt = time.perf_counter() - t0
    res.append(
        {
            "file": str(f.relative_to(ROOT)),
            "clean": not has_err(tree.root_node),
            "seconds": dt,
            "lines": lines,
        }
    )
    tot_s += dt
    tot_l += lines
out["B_tree_sitter_sql"] = {
    "files": len(res),
    "clean": sum(r["clean"] for r in res),
    "ms_per_kloc": 1000 * tot_s / (tot_l / 1000),
    "kloc": tot_l / 1000,
}

import sqlglot
from sqlglot import exp

res, tot_s, tot_l, cmd = [], 0.0, 0, 0
for f in files:
    text = f.read_text(errors="replace")
    lines = text.count("\n") + 1
    t0 = time.perf_counter()
    try:
        trees = sqlglot.parse(text, read="oracle")
        ok = True
        c = sum(1 for t in trees if isinstance(t, exp.Command))
        n = len(trees)
    except Exception as e:  # noqa
        ok, c, n = False, 0, 0
    dt = time.perf_counter() - t0
    res.append(
        {"file": str(f.relative_to(ROOT)), "ok": ok, "command_stmts": c, "stmts": n, "seconds": dt}
    )
    tot_s += dt
    tot_l += lines
out["C_sqlglot_oracle"] = {
    "files": len(res),
    "no_exception": sum(r["ok"] for r in res),
    "files_fully_structured": sum(1 for r in res if r["ok"] and r["command_stmts"] == 0),
    "stmts": sum(r["stmts"] for r in res),
    "command_stmts": sum(r["command_stmts"] for r in res),
    "ms_per_kloc": 1000 * tot_s / (tot_l / 1000),
}
out["versions"] = {"tree_sitter_language_pack": "1.22.1", "sqlglot": sqlglot.__version__}
json.dump(out, open(sys.argv[1], "w"), indent=1)
print(json.dumps(out, indent=1))
