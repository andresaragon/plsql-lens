"""Option A: ANTLR4 grammars-v4 sql/plsql (Apache-2.0) + antlr4-python3-runtime (BSD-3).

Setup (outside the repo, grammar commit 04b362f71d357f581d191969c3ae0e56be296eaa):
  java -jar antlr-4.13.2-complete.jar -Dlanguage=Python3 -o gen PlSqlLexer.g4 PlSqlParser.g4
Usage: python spike_a_antlr.py GEN_DIR OUT.json [--timeout 90]
Parse success = zero syntax errors. Units are extracted from the parse tree.
"""

import json, multiprocessing as mp, sys, time
from pathlib import Path

GEN = Path(sys.argv[1]).resolve()
OUT = sys.argv[2]
TIMEOUT = 90
ROOT = Path(__file__).resolve().parents[1]
EXTS = {".pks", ".pkb", ".tps", ".tpb", ".trg", ".plb", ".sql"}


def work(path: str):
    sys.path.insert(0, str(GEN))
    from antlr4 import CommonTokenStream, InputStream
    from antlr4.error.ErrorListener import ErrorListener
    from PlSqlLexer import PlSqlLexer
    from PlSqlParser import PlSqlParser

    class Err(ErrorListener):
        n = 0

        def syntaxError(self, *a):
            Err.n += 1

    text = Path(path).read_text(errors="replace")
    t0 = time.perf_counter()
    err = Err()
    lexer = PlSqlLexer(InputStream(text))
    lexer.removeErrorListeners()
    lexer.addErrorListener(err)
    parser = PlSqlParser(CommonTokenStream(lexer))
    parser.removeErrorListeners()
    parser.addErrorListener(err)
    tree = parser.sql_script()
    dt = time.perf_counter() - t0
    units = set()

    def name(c, attr):
        f = getattr(c, attr, None)
        if f is None:
            return None
        v = f()
        if isinstance(v, list):
            v = v[0] if v else None
        return v.getText().lower() if v is not None else None

    def walk(node, pkg, depth):
        cn = type(node).__name__
        if cn in ("Create_packageContext", "Create_package_bodyContext"):
            n = name(node, "package_name")
            if n:
                units.add(f"package:{n.split('.')[-1]}")
                pkg = n.split(".")[-1]
        elif cn in ("Create_procedure_bodyContext", "Create_function_bodyContext"):
            n = name(node, "procedure_name") or name(node, "function_name")
            if n:
                units.add(
                    ("procedure:" if "procedure" in cn.lower() else "function:") + n.split(".")[-1]
                )
        elif (
            cn
            in (
                "Procedure_specContext",
                "Function_specContext",
                "Procedure_bodyContext",
                "Function_bodyContext",
            )
            and depth == 0
            and pkg
        ):
            n = name(node, "identifier")
            if n:
                units.add(("procedure:" if "Procedure" in cn else "function:") + f"{pkg}.{n}")
        elif cn == "Create_triggerContext":
            n = name(node, "trigger_name")
            if n:
                units.add("trigger:" + n.split(".")[-1])
        d = depth + 1 if cn in ("Procedure_bodyContext", "Function_bodyContext") else depth
        for i in range(node.getChildCount()):
            ch = node.getChild(i)
            if hasattr(ch, "getRuleIndex"):
                walk(ch, pkg, d)

    walk(tree, None, 0)
    return {"errors": err.n, "seconds": dt, "lines": text.count("\n") + 1, "units": sorted(units)}


def run(path):
    with mp.get_context("spawn").Pool(1) as p:
        r = p.apply_async(work, (path,))
        try:
            return r.get(TIMEOUT)
        except mp.TimeoutError:
            p.terminate()
            return {"timeout": True}
        except Exception as e:  # noqa
            return {"exception": repr(e)[:200]}


if __name__ == "__main__":
    files = sorted(p for p in (ROOT / "corpus").rglob("*") if p.suffix in EXTS)
    if "--sample" in sys.argv:
        files = files[:: int(sys.argv[sys.argv.index("--sample") + 1])]
    from concurrent.futures import ThreadPoolExecutor

    with ThreadPoolExecutor(4) as ex:
        res = list(ex.map(lambda f: (str(f.relative_to(ROOT)), run(str(f))), files))
    json.dump(dict(res), open(OUT, "w"), indent=1)
    ok = sum(1 for _, r in res if r.get("errors") == 0)
    print(f"files={len(res)} clean={ok} rate={ok / len(res):.3f}")
