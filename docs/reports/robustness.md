# Parser robustness against malformed PL/SQL

Claim under test (README, F1): the parser *never raises on unknown syntax*. This report covers
issue #16. The parser and rules are frozen (see `tests/unit/test_external_frozen.py`), so nothing
here was fixed: failures are recorded and pinned with `xfail(strict=True)`.

## Method

`tests/robustness/` takes the 324 PL/SQL files under `corpus/` and `tests/fixtures/` as seeds and
mutates them with `random.Random(seed)`. The same seed gives the same list, byte for byte (checked by
a test); a shorter run is a prefix of a longer one.

| Operator | What it does |
|----------|--------------|
| `truncate` | cut the file at a random offset |
| `delete_token` / `duplicate_token` | remove or double one random token |
| `repeat_span` | repeat 1–4 consecutive tokens 10 to ~20 000 times (deep nesting, runaway quotes) |
| `unclosed_quote` | insert `'`, `"`, `q'[`, `q'{`, `n'` … at a random offset |
| `unclosed_comment` | insert `/*`, `/**`, `--` … at a random offset |
| `change_case` | upper, lower, swap, or swap a random slice |
| `line_endings` | replace every `\n` by `\r\n`, `\r` or `\n\r` |
| `bom` | prepend one or two U+FEFF |
| `compound` | one operator followed by 1–2 of truncate / quote / comment / BOM |

For each mutation the bytes are written to a scratch file and checked:

1. `parse_file` does not raise, returns a `FileIR` and finishes in under 2 s;
2. `review` (all rules) on that IR does not raise and finishes in under 5 s.

Both calls run under `signal.setitimer`; the alarm raises a `BaseException`, so a hang counts as a
failure exactly like an exception, and an infinite loop cannot freeze the run. The 5 s review limit
is a hang guard of ours (the issue only sets the 2 s budget for `parse_file`); normal reviews take
under 0.1 s. Besides the seeded sweep there is one Hypothesis property (`derandomize=True`, 300
examples) that truncates and inserts arbitrary Unicode text into a sample of the seed files.

Run it with `uv run pytest tests/robustness -m robustness` (also available as the manual
`robustness` workflow). It is excluded from the default run by `tests/robustness/conftest.py`.

## Result of the fixed-seed sweep

| | |
|---|---|
| Seed | `20261030` |
| Mutations | `2400` (minimum required: 2000) over 324 distinct seed files, ~230–255 per operator |
| Failures (exception, hang, slow, wrong type) | **0** |
| Total time of the sweep | 8.0 s |
| Slowest `parse_file` | 1.17 s (`tests/fixtures/rules/PLL005/pos_2.pkb` with a `repeat_span`; close to the 2 s limit) |
| Slowest `review` | 0.08 s |
| Whole `-m robustness` suite | about 21 s |

Exploratory runs outside the committed suite, with other seeds and a few thousand to 20 000
mutations each, reproduced nothing beyond the failure types below.

## Findings

The sweep itself is clean, but extreme repetition (which the `repeat_span` operator only reaches by
chance) breaks the claim in four ways. They were found with targeted probes and with larger
exploratory seeds, then minimized. Each is stored as a small JSON recipe in
`tests/robustness/findings/` (text parts × repeat count, so the input stays reviewable) and pinned by
a strict xfail in `tests/robustness/test_findings.py`. If the parser is ever fixed, the strict xfail
fails and the entry must be deleted.

| Finding | Stage | Minimal input | Failure |
|---------|-------|---------------|---------|
| `nested_subprograms_recursion` | parse | `create or replace package body p is` + `procedure a is` × 1500 | `RecursionError`. The exact threshold depends on how much stack the caller already uses: with the default limit of 1000 and a shallow caller (a plain script) 495 levels still pass and 700 fail; under pytest the same input fails from 495 levels, and with a deeper caller from fewer. The recipe uses 1500 so that it fails whatever the caller's depth. Needs the `create` form; without it the parser tolerates the same nesting. |
| `unclosed_q_quote_quadratic` | parse | `q'[` × 24 000 (72 KB) | ~8 s in `lexer.tokenize`; 8 000 take 0.9 s, 12 000 take 2.0 s. The q-string regex scans to the end of input for every unclosed opener: O(n²). |
| `parameter_modes_quadratic` | parse | `create package body p is procedure a (x in` + `out nocopy` × 30 000 + `integer) is begin null; end; end;` | ~7 s in `parse_params`: `rest = rest[1:]` per mode keyword, O(n²). 20 000 repetitions take 3 s. |
| `unclosed_loops_review_hang` | review | `procedure a is begin` + `loop;` × 1000 + `insert into t values (1);` × 30 | ~15 s in `PLL005.check`; the rule re-scans the statements for every enclosing loop of every DML statement. 400 loops and 40 statements already take 2.5 s. |

The repetition counts of the three timing findings carry a safety margin of 3–4× over the limit, so a
faster machine still fails them. All four need inputs far from real PL/SQL (hundreds to thousands of
identical tokens in a row); none was reachable with the single-token operators.

Nothing was inferred without a reproduction: each row was reproduced from its stored recipe by the
test suite.

## Not verified

- Only Linux was used. The guard needs `signal.setitimer`; elsewhere the suite is skipped.
- Time-based findings depend on machine speed within the margin described above.
- Other seeds or operators may find more; 0 failures in the fixed sweep is not a proof.
