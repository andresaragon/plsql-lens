# Wrong `unit` in `migrate` findings — diagnosis (issue #4)

**Verdict.** The wrong `unit` is a symptom. The cause is in the parser (`src/plsql_lens/parser/structure.py`, sealed by F4b): when
the `END` of a `CASE` *expression* is directly followed by `LOOP`, the body of the routine never closes and **every routine after it
is missing from the IR**. `migrate` only inherits that. Because the parser is frozen I did not change it: this PR adds the
minimal reproducer as two `xfail(strict=True)` tests and the proposed patch is at the end of this report for the owner to decide.

Everything marked *(run)* was executed in this session and the command is given. What is marked *(reading)* is my reading of the
code and was not executed. `unit` is informative (no rule uses it); it is not used here to measure anything.

## 1. Root cause

**Minimal reproducer** *(run)*. `MINIMAL` in `tests/unit/test_migrate_unit_attribution.py` (19 lines, written for this repo; a
function whose loop bound is `CASE ... END` with `LOOP` right after it, followed by a second function with a `SYSDATE`):

```bash
uv run pytest tests/unit/test_migrate_unit_attribution.py -q -rx
```

With the current parser, `parse_source` lists only `first_fn` (lines 3–18, i.e. up to the end of the file), `ir.issues` has
`unexpected end of file in package pkg_min`, and the `MIG003` finding at line 15 gets `unit = pkg_min.first_fn` although the line
belongs to `second_fn`. The same happens with `WHILE CASE ... END LOOP` on one line, and with `END` and `LOOP` on the same line
(`FOR i IN 1 .. CASE ... END LOOP`). Putting the `CASE` between parentheses makes it work (control test, passing).

**Function** *(reading, then confirmed by the patch in section 4)*: `_Parser.parse_block_body`, the `end` branch
(`structure.py`, lines 343–349 in `f05de7f`). It keeps a `stack` of open blocks (`begin`, `if`, `loop`, `case`). For an `END`
followed by `IF`, `LOOP` or `CASE` it assumes the two words close a statement (`END LOOP`):

```python
if nxt is not None and nxt.kind == IDENT and nxt.text in ("if", "loop", "case"):
    if stack and stack[-1] == nxt.text:
        stack.pop()
    self.i += 2  # skips both tokens even when nothing was popped
    continue
```

In `FOR i IN 1 .. CASE WHEN p THEN 8 ELSE 7 END LOOP`, `case` is pushed, then `END LOOP` arrives with `case` on top of the stack.
The top does not match `loop`, nothing is popped, and both tokens are skipped: the `CASE` stays open and the `LOOP` that opens the
loop is never pushed. From then on the stack is one level too deep (the real `END LOOP` is skipped the same way), the routine's own
`END first_fn;` only closes the stray `case`, and the scan runs on through the next routines until the end of the file, where it
reports `unterminated body of <routine>`.

**Why `sha512` and `randombytes` are not in the inventory, and what happens to the end of `sha256`** *(run)*, on `oos-utils`
(`b6217292bc744211eaee9e1d11ca7a0b495bc44d`, MIT; cloned to a temporary directory, not stored here): `sha256` contains
`for i in 1 .. case when p_256 then 8 else 7 end` followed on the next line by `loop`. For this file the parser reports

```text
ParseIssue(line=721, 'unterminated body of sha256')
ParseIssue(line=2416, 'unexpected end of file in package oos_util_crypto')
```

`sha256` has no end: its span is 687–2416, the last line of the file (`end oos_util_crypto;`), and `sha512`, `randombytes` and the rest
are inside that span, so they are not separate subprograms. `_with_unit` in `migrate/rules.py` takes the smallest span that
contains the line, and the smallest is `sha256`. The parser records the problem in `ir.issues`; I did not check whether any command
prints it.

## 2. Scope

**Method, independent of the parser** *(run)*. `tests/unit/test_migrate_unit_attribution.py` contains a text scan: it blanks
comments, strings and `q'[...]'` literals, finds the headers `function|procedure <name>` whose declaration reaches `IS`/`AS`
before a `;` (so forward declarations and specifications are skipped), and for each finding of `migrate` takes the header just
before the finding's line and the earlier headers with smaller indentation. It uses neither the parser nor `_unit_spans`. It reads
no `END`, so it cannot see where a routine stops; it is a reference, **not ground truth**. Its own limits showed up in the
results below.

```bash
# corpus (current main)
uv run python tests/unit/test_migrate_unit_attribution.py corpus
# oos-utils at the fixed commit, in a temporary directory
D=$(mktemp -d) && git -C "$D" init -q && git -C "$D" fetch -q --depth 1 https://github.com/OraOpenSource/oos-utils b6217292bc744211eaee9e1d11ca7a0b495bc44d && git -C "$D" checkout -q FETCH_HEAD
(cd "$D" && uv run --project "$OLDPWD" python "$OLDPWD/tests/unit/test_migrate_unit_attribution.py" source)
```

| | `corpus/` | `oos-utils` `source/` |
|---|---|---|
| Findings of `migrate` (all rules at `f05de7f`) | 506 | 95 |
| Routines with a body (text scan) | 1371 | 107 |
| Routines the parser does not list | 0 | 18 distinct names, all in `oos_util_crypto.pkb` |
| `unit` = routine of the last header before the line | 442 | 56 |
| `unit` = an enclosing routine (a nested routine ended before the line) | 26 | 7 |
| Line outside any routine body by the text scan (not compared) | 15 | 27 |
| `unit` disagrees with the text scan | 23 (in 3 files) | 5 (in 1 file) |

The 5 in `oos-utils` are the five of the issue (lines 880, 943, 945, 1229, 1237 of `oos_util_crypto.pkb`). The 18 missing names:
`sha512`, `hash`, `hash_str`, `mac`, `mac_str`, `randombytes`, `aes_encrypt_key`, `aes_decrypt_key`, `aes_encrypt`, `aes_decrypt`,
`deskey`, `des`, `encrypt__rc4`, `encrypt`, `decrypt` and the nested `grv`, `encr`, `decr` (the script prints them).

The 23 disagreements in `corpus/` are **limits of the text scan, not errors of the tool**; I read each group:

* `hr_code.sql:110` (1): the line is inside `CREATE TRIGGER update_job_history`; the tool says `update_job_history`, which is right.
  The scan only knows functions and procedures and thinks the previous procedure goes on.
* `poe_v3.sql:107` (1): the line is inside a `CREATE VIEW` that comes after a function; the tool says no unit, which is right.
* `ut_compound_data_helper.pkb:821–841` (21): the lines are in the package initialization block (`begin` at line 797, `end;` at 852);
  the tool says the package, which is right.

So on `corpus/` I found **no** wrong `unit` and no routine missing from the IR; the trigger that would produce the defect is not
present there. On `oos-utils` the effect is confined to one file out of 26. That is two projects: nothing here says how common the
construct is in other code.

**Beyond what the issue describes** (owner's adjustment 4). It is bigger than a label: in `oos_util_crypto.pkb` the IR lacks 18
routines (all their parameters, call sites and body statements are missing for anything that reads the IR: `inventory`, the call
graph and the `review` rules, not only `migrate`), and the package unit is not closed (`end_line` 0, the parse issue above). I
measured the missing routines; I did not run `review` on that file to see which findings change.

## 3. Why I did not fix it in `migrate`

The fix is not local to `src/plsql_lens/migrate/**`: `_unit_spans` receives an IR in which the routines do not exist, and
rebuilding them in `migrate` would mean a second routine parser. So there is no red-then-green pair of commits for this part. The
changes in this PR for part B are the reproducers (two `xfail(strict=True)`, plus four tests that pass and describe the current
behavior and the text scan) and this report.

## 4. Proposed patch (not applied)

```diff
--- a/src/plsql_lens/parser/structure.py
+++ b/src/plsql_lens/parser/structure.py
@@ -345,6 +345,12 @@ class _Parser:
                     if nxt is not None and nxt.kind == IDENT and nxt.text in ("if", "loop", "case"):
                         if stack and stack[-1] == nxt.text:
                             stack.pop()
+                        elif nxt.text == "loop" and stack and stack[-1] == "case":
+                            # `END` closes a CASE expression (`FOR i IN 1 .. CASE ... END LOOP`);
+                            # the LOOP that follows opens a loop and is read on its own.
+                            stack.pop()
+                            self.i += 1
+                            continue
                         self.i += 2
                         continue
```

I applied it in a scratch `git worktree` (not in this branch) and ran *(run)*:

* the minimal reproducer: both routines are listed, no parse issue, the finding gets `pkg_min.second_fn`; with the `xfail` markers
  removed the six tests of the new file pass (with the markers they report `XPASS(strict)`, which is the signal to remove them);
* `oos_util_crypto.pkb`: no parse issue; routines the parser does not list 18 → 0; disagreements on `oos-utils` 5 → 0;
* `corpus/` with the patch: the same numbers as without it (506 findings, 23 disagreements, all scan limits);
* the review rules and the IR counts (units, subprograms) of the 514 files that `collect_files` finds under `corpus/`,
  `docs/benchmarks/data/`, `docs/benchmarks/external/data/` and `tests/heldout/` are identical with and without the patch (`rules.RULES` run on each file);
* the default test selection (`-m 'not integration'`, 1200 tests then): 1 failure, `test_external_frozen.py`; nothing else fails.
  `docs/benchmarks/seal.json` holds hashes of the data splits, not of the parser, and its tests pass.

**Effect on the seal if the owner applies it.** `tests/unit/test_external_frozen.py` compares the SHA-256 of
`src/plsql_lens/parser/*.py`, `src/plsql_lens/rules/*.py` and `docs/rules.md` with `docs/benchmarks/external/frozen.json`. The patch
changes one file and therefore the aggregate:

| `docs/benchmarks/external/frozen.json` | now | with the patch |
|---|---|---|
| `files["src/plsql_lens/parser/structure.py"]` | `529e9c2d753fc790298278e5bc5e1f0db0d084be54271f7dc9ee800387242ed3` | `2e9ef0b7bcdae991ed9b2ee5eab79539ed0676b7bdda7322b430e286c1dedce4` |
| `engine_sha256` | `114ad81d3b5ee6e2296c536ba80924cb8fa67ad2bd01ceaa6ef756dcd53032bf` | `1129ca4fb4b54050b3fe261547edbead8a1fe9f0f06d76ae718446fa12a0131e` |

Unfreezing means editing `frozen.json` (and deciding whether the F4b external evaluation, which says the engine must not change
while it exists, stays valid; in my run the review findings on its data did not change, but that is the owner's call). Together
with the patch, the two `xfail` markers in `tests/unit/test_migrate_unit_attribution.py` must be removed.

## 5. What was not verified

* The patch was not run on PostgreSQL or Oracle (not relevant here) and **not** committed: it exists only in a scratch worktree.
* I did not run `review` on `oos_util_crypto.pkb` with and without the patch; the 514-file comparison covers `corpus/` and the
  benchmark data, not `oos-utils`.
* The 66 tests excluded by `-m 'not integration'` were not run, and `tests/heldout/` contains `MANIFEST.md` and `labels.json` only (no PL/SQL sources), so it adds no files to the comparison.
* Only two projects were scanned. Other constructs that open or close a block ambiguously (for example `END` of a `CASE`
  expression followed by `IF` or `CASE`) were not looked for; I tested `FOR ... CASE ... END LOOP` and `WHILE CASE ... END LOOP`.
* The text scan is not ground truth (section 2).
