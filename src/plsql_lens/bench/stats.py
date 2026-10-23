"""Wilson score intervals and precision/recall/F1 with intervals."""

from __future__ import annotations

from math import sqrt
from typing import Any

Z95 = 1.959964


def wilson(k: float, n: float, z: float = Z95) -> tuple[float, float]:
    """95 % Wilson score interval for a proportion ``k / n``; ``(0, 1)`` when ``n`` is 0."""
    if n <= 0:
        return (0.0, 1.0)
    p = k / n
    denom = 1 + z * z / n
    centre = (p + z * z / (2 * n)) / denom
    half = z * sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / denom
    lo = 0.0 if k <= 0 else max(0.0, centre - half)
    hi = 1.0 if k >= n else min(1.0, centre + half)  # exact at the boundaries
    return (lo, hi)


def prf(tp: int, fp: int, fn: int) -> dict[str, Any]:
    """Counts, precision, recall and F1, each with a Wilson interval (``None`` when undefined).

    F1 = TP / (TP + (FP + FN) / 2) is treated as a proportion for its interval, an approximation.
    """
    out: dict[str, Any] = {"tp": tp, "fp": fp, "fn": fn}
    for name, num, den in (
        ("precision", tp, tp + fp),
        ("recall", tp, tp + fn),
        ("f1", tp, tp + (fp + fn) / 2),
    ):
        if den > 0:
            out[name] = num / den
            out[f"{name}_ci"] = wilson(num, den)
        else:
            out[name] = None
            out[f"{name}_ci"] = None
    return out
