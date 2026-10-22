"""Print F1 / precision / recall of the inventory against the hand-labeled ground truth."""

import json
import sys
from pathlib import Path

from plsql_lens.inventory import build_inventory

ROOT = Path(__file__).resolve().parents[1]


def prf(pred: set, gold: set) -> tuple[float, float, float]:
    tp = len(pred & gold)
    p = tp / len(pred) if pred else 1.0
    r = tp / len(gold) if gold else 1.0
    return (2 * p * r / (p + r) if p + r else 0.0, p, r)


def main() -> None:
    verbose = "-v" in sys.argv
    for gt_path in sorted((ROOT / "tests/acceptance/ground_truth").glob("*.json")):
        gt = json.loads(gt_path.read_text())
        inv = build_inventory([ROOT / f for f in gt["files"]])
        for what, pred, gold in (
            ("units", {u.key for u in inv.units}, set(gt["units"])),
            ("edges", {(e.caller, e.callee) for e in inv.edges}, {tuple(e) for e in gt["edges"]}),
        ):
            f, p, r = prf(pred, gold)
            print(
                f"{gt_path.stem:14} {what:5} F1={f:.3f} P={p:.3f} R={r:.3f} "
                f"(pred {len(pred)}, gold {len(gold)})"
            )
            if verbose:
                print("  FP:", sorted(pred - gold)[:15], "\n  FN:", sorted(gold - pred)[:15])


def params_report() -> None:
    gt_path = ROOT / "tests/acceptance/ground_truth_params/params_logger.json"
    if not gt_path.exists():
        return
    gt = json.loads(gt_path.read_text())
    inv = build_inventory([ROOT / gt["file"]])
    by_key = {u.key: u for u in inv.units}
    gold = {(k, i, n, m) for k, ps in gt["params"].items() for i, (n, m) in enumerate(ps)}
    pred = {
        (u.key, i, p.name, p.mode)
        for u in by_key.values()
        if u.key in gt["params"]
        for i, p in enumerate(u.params)
    }
    f, p, r = prf(pred, gold)
    print(
        f"{'params_logger':14} params F1={f:.3f} P={p:.3f} R={r:.3f} "
        f"(pred {len(pred)}, gold {len(gold)})"
    )
    if "-v" in sys.argv:
        print("  FP:", sorted(pred - gold)[:10], "\n  FN:", sorted(gold - pred)[:10])


main()
params_report()
