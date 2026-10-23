# Human-written split (F4b) — authoring guide

The seeded `test` split showed a ceiling effect: rules and the LLM-only baseline both scored almost perfectly,
because the defects were written by an LLM from the same contract (`docs/rules.md`). This split breaks that
loop. Every case here is written by hand by a senior PL/SQL developer, from scratch, without running
PL/SQL Lens on it first.

## Hard rules for authors
1. **Write from scratch.** Do not copy, paraphrase or reconstruct code, schemas, table names or business
   rules from any employer or client. Use neutral domains (library, shop, payroll, ticketing, inventory…).
2. **Do not run `plsql-lens` on a case before it is committed.** The rule engine sees a case for the first
   time during adjudication (see below).
3. One file per case, 20–120 lines, valid-looking PL/SQL (it does not have to compile; it has to be
   something a reviewer would believe came from a real code base).
4. No secrets, no real names, no real data.

## Markers
Put markers as **trailing comments on the exact line** the rule's *Location* column names in
`docs/rules.md` (for example, the `WHEN OTHERS` line for PLL001, the `COMMIT` line for PLL003).

| Marker | Meaning | Scored as |
|---|---|---|
| `-- expect: PLL00n` | A defect that the rule's contract covers. The rule should fire on this line. | recall / precision (main table) |
| `-- beyond: PLL00n` | A real defect of the same family that the contract does not cover (for example a `COMMIT` inside a procedure that a loop calls). | "real-world recall", reported apart |
| `-- clean: PLL00n` | A hard negative: code that looks like the defect but is correct. The rule must not fire anywhere in the enclosing subprogram. | false positives |

Several markers can share a line: `-- expect: PLL002 expect: PLL007`. Free text after a marker is allowed
(`-- beyond: PLL003 (renew_one commits)`).
Everything not marked is assumed clean. A finding on an unmarked line counts as a false positive, so mark
**every** defect you know of, even incidental ones.

## Header (first lines of each file)
```sql
-- case: h001
-- domain: library loans
-- difficulty: easy | medium | hard
-- note: one line on what makes this case realistic or tricky
```

## What makes a good case
- Patterns seen in real code reviews, written in a different domain: defects hidden in long procedures,
  nested blocks, handlers in outer scopes, dynamic SQL built in several steps, cursors fetched by hand.
- Hard negatives that a naive pattern match would flag: binds that look like concatenation,
  `ROLLBACK TO savepoint` inside a loop, `SELECT INTO` protected by an outer handler, `FORALL` with
  DML, a `TO_DATE` with a format mask on the next line.
- Mix of difficulties. Do not write only cases the rules will obviously catch, and do not write only
  traps.

## Target size
At least **5 `expect` and 5 `clean` markers per rule** (70 + 70), plus as many `beyond` markers as come
naturally, spread over 30–40 files. PLL007 (repeated literals) needs only the minimum.

## Workflow
1. Write the cases in `docs/benchmarks/human/cases/` (`h001.pkb`, `h002.pkb`, …). `_TEMPLATE.pkb` is an
   example and is excluded from scoring.
2. Commit them. That commit is the seal: its SHA goes into `docs/benchmarks/seal.json`.
3. A converter (built in F4b) strips the markers, writes the clean files and a manifest in the same
   format as the seeded splits, and runs the frozen "after" rules and the LLM-only baseline.
4. **Adjudication:** every finding on an unmarked line is listed. The author decides, case by case,
   whether it is a real defect that was missed (add a marker and record the change) or a false positive
   (leave it). Every decision is published with its reason. Rules are never tuned on this split.
