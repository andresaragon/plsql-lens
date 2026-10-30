"""Summarise docs/reports/phase-5/adjudication.json as the tables of docs/reports/phase-5.md (F5c).

    python scripts/migrate_adjudication.py

Prints, per rule, how many findings exist, how many were adjudicated, how many are true positives and how
the adjudicated ones split by impact. The Wilson 95 % lower bound is given only for the sampled rules; the
other rules were adjudicated completely, so there is no sampling uncertainty. Nothing here calls an LLM.
"""

import collections
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DOC = json.loads((ROOT / "docs" / "reports" / "phase-5" / "adjudication.json").read_text())
ORDER = ["mechanical", "needs-rewrite", "semantic-trap", "benign"]


def wilson_lower(k: int, n: int, z: float = 1.96) -> float:
    p = k / n
    centre = p + z * z / (2 * n)
    spread = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n))
    return (centre - spread) / (1 + z * z / n)


def main() -> None:
    by_rule: dict[str, list[dict[str, object]]] = collections.defaultdict(list)
    for it in DOC["items"]:
        by_rule[str(it["rule"])].append(it)
    head = "| Rule | Findings | Adjudicated | How | True positives | Wilson 95 % lower (sampled only) | "
    print(head + " | ".join(ORDER) + " |")
    print("|---|---|---|---|---|---|" + "---|" * len(ORDER))
    total = tp_total = 0
    impacts: collections.Counter[str] = collections.Counter()
    for rule in sorted(by_rule):
        items, stratum = by_rule[rule], DOC["strata"][rule]
        tp = sum(i["verdict"] == "tp" for i in items)
        by_impact = collections.Counter(str(i["impact"]) for i in items)
        complete = stratum["how"] == "all"
        bound = "complete" if complete else f"{wilson_lower(tp, len(items)):.2f}"
        cells = " | ".join(str(by_impact[k]) for k in ORDER)
        how = "all" if complete else "sample"
        print(
            f"| {rule} | {stratum['population']} | {len(items)} | {how} | {tp}/{len(items)} | {bound} | {cells} |"
        )
        total, tp_total = total + len(items), tp_total + tp
        impacts.update(by_impact)
    cells = " | ".join(str(impacts[k]) for k in ORDER)
    print(f"| **All** | 234 | {total} | | {tp_total}/{total} | | {cells} |")


if __name__ == "__main__":
    main()
