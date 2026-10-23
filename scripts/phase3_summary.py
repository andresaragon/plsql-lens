"""Markdown tables from a testgen-suite report.json (stdout)."""

import json
import sys

d = json.load(open(sys.argv[1]))  # noqa: SIM115


def pct(x: float | None) -> str:
    return "n/a" if x is None else f"{100 * x:.1f} %"


def row(name: str, s: dict) -> str:  # type: ignore[type-arg]
    return (
        f"| {name} | {s['units']} | {s['compiled']} ({pct(s['compile_rate'])}) | {s['ran']} "
        f"| {s['tests']} | {s['passed']} | {s['failed']} | {s['errored']} ({pct(s['pass_rate'])} pass) "
        f"| {s['repair_rounds']} | {s['assertions_per_test'] and round(s['assertions_per_test'], 2)} "
        f"| {s['input_tokens']}/{s['output_tokens']} | {s['cost_usd']:.3f} "
        f"| {s['cost_usd_per_test'] and round(s['cost_usd_per_test'], 4)} |"
    )


print("| Slice | Units | Compiled | Ran | Tests | Passed | Failed | Errored | Repair rounds "
      "| Assertions/test | Tokens in/out | USD | USD/test |")  # fmt: skip
print("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
print(row("**Total**", d["total"]))
for lvl, s in d["by_difficulty"].items():
    print(row(lvl, s))
print()
print("| Unit | Difficulty | Compiled | Tests | Passed | Failed | Errored | Repairs | USD |")
print("|---|---|---|---|---|---|---|---|---|")
for u in d["units"]:
    print(f"| {u['id']} | {u['difficulty']} | {'yes' if u['compiled'] else 'NO'} | {u['tests']} "
          f"| {u['passed']} | {u['failed']} | {u['errored']} | {u['repair_rounds']} | {u['cost_usd']:.3f} |")  # fmt: skip
