# ADR 0002 — Statement layer for review rules

Status: accepted (2026-10-22). Phase F2. Does not change ADR 0001 (parser = option D).

## Problem
The F1 IR models units, parameters and call sites, not statements. The F2 rules need to know about
loops, `EXCEPTION` handlers, `SELECT … INTO`, DML and `EXECUTE IMMEDIATE`, and where each sits.

## Options
* **A. Statement/expression AST in the parser.** Most precise; ~600 extra lines in a parser that is
  deliberately tolerant, and every unknown construct becomes a decision point.
* **B. Per-rule token patterns with their own scope tracking.** Cheapest per rule, but every rule
  re-implements block/loop/handler bookkeeping (END IF vs END LOOP vs END, expression CASE).
* **C. Hybrid (chosen).** One pass in the parser splits each body into flat `Stmt` records
  (`kind`, tokens, enclosing-construct `context`, line/col). Rules filter that list and inspect the
  few tokens they need.

## Measurement (throw-away B prototype over the 264-file corpus, 0.25 s)
| Pattern | Hits |
|---|---|
| `WHEN OTHERS` handlers | 16 (9 contain a RAISE; 6 end in e.g. `return false` with no raise/log; 1 `NULL`) |
| `COMMIT`/`ROLLBACK` inside a loop | 1 (xdbUtilities.sql:595) |
| `EXECUTE IMMEDIATE` | 49, of which 25 concatenate (`\|\|`) |

The prototype needed a scope stack with loop/handler/case handling to get these right; that stack is
exactly what C centralises. After implementing C the same counts were reproduced from `Stmt`
(5 515 statements; 16 `WHEN OTHERS`, 1 commit in loop), so the layer loses nothing B found.

## Criteria
| | False positives (corpus) | Maintainability | Cost of a new rule in F4 |
|---|---|---|---|
| A | lowest in principle | high parser surface | low, once the AST exists |
| B | same as C for the 3 probed patterns | scope logic duplicated per rule | medium: copy/paste bookkeeping |
| C | same as B on the probe | one ~200-line module + tests | low: a filter over `Stmt` |

## Decision
Option C: `parser/statements.py` produces `Stmt` tuples stored on `Subprogram.body` and `Unit.body`
(standalone body, trigger body, package initialization block), plus `end_line` for block-level
suppression. Expression syntax stays unparsed; rules that need it (PLL002, PLL006, PLL007) read tokens.

## Consequences
* Rules are pure functions `Stmt`/`Subprogram` → findings; no rule touches the lexer scope logic.
* Limits: no expression structure, no types, nested `DECLARE` sections are flattened, both branches of
  `$if` are kept. Rules must state which of these produce false negatives.
* If F4 shows rules needing expression structure, revisit A for expressions only (needs approval).
