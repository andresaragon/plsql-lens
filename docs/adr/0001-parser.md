# ADR 0001 — Parser for PL/SQL structure

Status: accepted (2026-10-22). Phase F1.

## Context

SPEC §3 lists four parser options. The spike measured each on the 264-file / 29.5 KLOC corpus
(`corpus/`, see NOTICE) and, where the option can produce an inventory at all, against the
hand-labeled ground truth in `tests/acceptance/ground_truth/` (labels were written by reading the
source, before the implementation existed). Spike code: `spikes/`; raw results: `spikes/results/`.

## Measurements

| | A. ANTLR4 `grammars-v4/sql/plsql` | B. tree-sitter | C. `sqlglot` (Oracle) | D. hand-written tolerant parser |
|---|---|---|---|---|
| Parse success (no fatal error) | 30/33 = **90.9 %** (every 8th file; full run not completed, see below) | **0/264** error-free trees (generic `sql` grammar; no PL/SQL grammar found) | no exception on 113/264 = **42.8 %**, and all 113 are opaque `Command` nodes | **264/264 = 100 %**, no structural issue reported |
| Time per KLOC | **27 958 ms** (147 s for 5.3 KLOC) | 14.9 ms | 16.2 ms | **9.4 ms** (277 ms for the whole corpus) |
| Inventory accuracy vs ground truth | ut_metadata.pks: 22/22 units (same as D); logger.pkb: 13 syntax errors, 8 of 57 units recovered; calls not extracted | not applicable (no PL/SQL nodes) | not applicable (PL/SQL is a `Command` string) | units F1 **1.000** / **1.000**; call edges F1 **0.982** / **0.994** (logger+hr / utPLSQL core) |
| Install footprint | Java at build time; generated `PlSqlParser.py` 6.5 MB + lexer 1.2 MB; runtime `antlr4-python3-runtime` 4.13.2; the grammar's embedded actions are Java (`this.`, `&&`) and had to be patched by hand to run on the Python target | `tree-sitter` + `tree-sitter-language-pack` 1.22.1 (5.7 MB; grammars fetched at first use) | `sqlglot` 30.24.0, pure Python | 0 dependencies, ~1.2 kLOC of Python in this repo |
| License | grammar Apache-2.0, runtime BSD-3 | per grammar (not adopted) | MIT | ours (MIT) |

Notes on the numbers:
* A: the full-corpus run was stopped (at ~28 s/KLOC the 29.5 KLOC corpus needs ~14 CPU-minutes) and
  replaced by a deterministic sample (every 8th file, 33 files). The three files with syntax errors
  include `logger.pkb`, the largest labeled file. Grammar commit
  `04b362f71d357f581d191969c3ae0e56be296eaa`, ANTLR 4.13.2.
* D parse rate is measured on the same corpus the parser was developed against (two lexer bugs found
  through corpus failures were fixed: SQL*Plus line blanking and `RETURN SELF AS RESULT`), so it is not
  a held-out number. Ground-truth labels were not used to tune the parser: the remaining false
  positives/negatives are listed in `docs/reports/phase-1.md`.
* B/C timings are single runs on one machine (4 vCPU) and include no PL/SQL understanding.

## Decision

**Option D**: a hand-written tolerant lexer plus structural recursive-descent parser
(`src/plsql_lens/parser/`). It is the only option that meets the F1 acceptance targets, it is two to
three orders of magnitude faster than A, and it adds no dependency. Weakness accepted: we own the
coverage, so unusual syntax degrades to partial IR (reported through `FileIR.issues`) rather than
failing.

**Option C is not adopted in F1.** `sqlglot` cannot parse PL/SQL blocks and F1 does not need embedded
SQL. Whether to use it for embedded-SQL analysis in F2 (rules PLL002/004/005/006) will be decided with
that phase's data; it would be a new runtime dependency and therefore needs approval (SPEC §8).

**Option A is rejected** for speed (≈3000× slower), generated-code size, a Java build step, and
error recovery that loses most of a file once one construct fails (`logger.pkb`).
**Option B is rejected**: no usable PL/SQL grammar.

## Consequences

* The IR (`parser/ir.py`) is ours; F2 rules consume it directly.
* Known gaps are tracked in the F1 report (overloads of different kinds collapse to the first
  declared kind; no type resolution; name-based call resolution).
* Revisiting this decision after the ADR requires approval (SPEC §8).
