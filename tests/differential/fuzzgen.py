"""Pure, seeded generator of integer ``NVL``/``DECODE`` statements for differential fuzzing (F5-G1).

Every statement is ``SELECT <expr> FROM (SELECT CAST(NULL AS INTEGER) n1, CAST(NULL AS INTEGER) n2,
1 v1, 2 v2, 2 v3, 7 v4 FROM DUAL)`` where ``<expr>`` is an INTEGER expression of at most three
nested calls: ``NVL(e, e)``, ``DECODE(e, s1, r1 [, s2, r2 [, s3, r3]] [, default])`` and an
occasional ``e + 1``. Operands are the columns, the integer literals 0-9 and
``CAST(NULL AS INTEGER)``; a bare ``NULL`` only appears as a literal DECODE search value. No
strings, ``''``, ``||`` or mixed types: those differences between Oracle and PostgreSQL are
already known and would only produce noise.
"""

from __future__ import annotations

import random
from dataclasses import dataclass

from plsql_lens.parser.lexer import IDENT, OP, tokenize

DEFAULT_SEED = 20261030
DEFAULT_N = 2000
COLUMNS = ("n1", "n2", "v1", "v2", "v3", "v4")
BASE = (
    "SELECT {expr} FROM (SELECT CAST(NULL AS INTEGER) n1, CAST(NULL AS INTEGER) n2, "
    "1 v1, 2 v2, 2 v3, 7 v4 FROM DUAL)"
)
_MAX_DEPTH = 3


@dataclass(frozen=True, slots=True)
class Statement:
    id: str
    sql: str


def _operand(rng: random.Random) -> str:
    r = rng.random()
    if r < 0.55:
        return rng.choice(COLUMNS)
    if r < 0.9:
        return str(rng.randrange(10))
    return "CAST(NULL AS INTEGER)"


def _expr(rng: random.Random, depth: int) -> str:
    """An integer expression with at most ``depth`` nested calls."""
    if depth == 0:
        return _operand(rng)
    r = rng.random()
    if r < 0.2:
        return _operand(rng)
    if r < 0.9:
        return _call(rng, depth)
    return f"{_expr(rng, depth - 1)} + 1"


def _call(rng: random.Random, depth: int) -> str:
    if rng.random() < 0.4:
        return f"NVL({_expr(rng, depth - 1)}, {_expr(rng, depth - 1)})"
    args = [_expr(rng, depth - 1)]
    for _ in range(rng.choice([1, 1, 2, 3])):
        r = rng.random()
        search = "NULL" if r < 0.15 else _operand(rng) if r < 0.7 else _expr(rng, depth - 1)
        args += [search, _expr(rng, depth - 1)]
    if rng.random() < 0.6:
        args.append(_expr(rng, depth - 1))
    return f"DECODE({', '.join(args)})"


def generate_statements(seed: int, n: int) -> list[Statement]:
    """``n`` distinct statements; the same seed always gives the same list (prefix-stable)."""
    rng = random.Random(seed)
    seen: set[str] = set()
    out: list[Statement] = []
    attempts = 0
    while len(out) < n:
        attempts += 1
        if attempts > 50 * n + 1000:
            raise RuntimeError("the generator ran out of distinct statements")
        expr = _call(rng, rng.choice([1, 2, 3, 3]))
        if rng.random() < 0.08:
            expr += " + 1"
        sql = BASE.format(expr=expr)
        if sql in seen:
            continue
        seen.add(sql)
        out.append(Statement(f"g{len(out):05d}", sql))
    return out


def max_call_depth(sql: str) -> int:
    """Deepest nesting of NVL/DECODE calls in ``sql``."""
    stack: list[bool] = []
    deepest = 0
    toks = tokenize(sql)
    for i, t in enumerate(toks):
        if t.kind == OP and t.text == "(":
            stack.append(
                i > 0 and toks[i - 1].kind == IDENT and toks[i - 1].text in ("nvl", "decode")
            )
            deepest = max(deepest, sum(stack))
        elif t.kind == OP and t.text == ")" and stack:
            stack.pop()
    return deepest
