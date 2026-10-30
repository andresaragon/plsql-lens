# Migration rules (F5a) — contract

`plsql-lens migrate` reports Oracle constructs that need attention when PL/SQL moves to PostgreSQL.
It is the migration counterpart of the review rules in [`rules.md`](rules.md) and follows the same
conventions: findings are deterministic functions of the source, an LLM never creates or removes a
finding, and a finding is reported at the `line` of the construct named under *Location*. These
rules live in their own package (`plsql_lens.migrate`, `MIGRATION_RULES`); they are **not** part of
`plsql_lens.rules.RULES`, and `review` does not run them.

A fixture marks an expected finding with a trailing comment `-- expect: MIGnnn` on that line; a
negative fixture has no marker for the rule under test. Fixture code must be valid-looking PL/SQL
written for this repo.

## How the rules read the source

The rules work on the tokens of the **whole file** (`parser.lexer.tokenize`), not on statement
bodies, so declarations are covered too. In that token stream:

* identifiers are lowercase (a quoted identifier keeps its case without the quotes);
* comments and `$IF` / `$THEN` / `$ELSE` / `$END` directives are gone, and both branches of a
  conditional-compilation block are kept;
* a string literal is one token that keeps its quotes, so the empty string is the text `''`, and
  anything inside a string or a comment is never a match.

"Preceded by" and "followed by" refer to the adjacent tokens in that stream (spaces, line breaks and
comments between them do not matter). `ident` means an identifier token. The enclosing unit of a
finding (`Finding.unit`) is the qualified name of the innermost subprogram or unit whose line range
contains the finding, when there is one.

## Rules

Severity: **high** = silent change of behavior, or no PostgreSQL equivalent; **medium** = manual
rewrite; **low** = mechanical rewrite.

| Rule | Severity | Flags | Location |
|---|---|---|---|
| MIG001 | low | A call to `NVL`: the identifier `nvl` followed by `(` and not preceded by `.`. PostgreSQL: `COALESCE`. | the `nvl` token |
| MIG002 | low | A call to `DECODE`: the identifier `decode` followed by `(` and not preceded by `.`. If a *search argument* is the literal `NULL`, the message says so: `DECODE` matches `NULL` with `NULL`, while `CASE x WHEN NULL` never matches. A search argument is an argument at an even position (2nd, 4th, …) that is followed by a result argument in the same call; the last argument (the default) is not one. An argument is "the literal `NULL`" when its tokens are exactly the identifier `null`. | the `decode` token |
| MIG003 | medium | The identifier `SYSDATE` or `SYSTIMESTAMP`, anywhere (strings and comments excluded by the token stream). In Oracle `SYSDATE` is a `DATE`, so `sysdate - d` is a number of days; in PostgreSQL the same expression is an interval (and `+ 1` is an error). | the token |
| MIG004 | low | A dotted chain that ends in `.nextval` or `.currval` (`seq.nextval`, `sch.seq.currval`): the identifier `nextval` or `currval` preceded by `.` and, before that, an identifier. PostgreSQL: `nextval('seq')` / `currval('seq')`. | the `nextval` / `currval` token |
| MIG005 | medium | The identifier `ROWNUM` not preceded by `.`. PostgreSQL: `LIMIT`, or `row_number()`. | the token |
| MIG006 | medium | `CONNECT` immediately followed by `BY` (hierarchical query). PostgreSQL: `WITH RECURSIVE`. | the `connect` token |
| MIG007 | medium | Three consecutive tokens `(`, `+`, `)` (the old outer-join operator). PostgreSQL: `LEFT JOIN` / `RIGHT JOIN`. | the `(` |
| MIG008 | high | `PRAGMA` immediately followed by `AUTONOMOUS_TRANSACTION`. PostgreSQL has no equivalent (dblink, `pg_background`, or a redesign). | the `pragma` token |
| MIG009 | low | A call whose dotted chain is `DBMS_OUTPUT.<name>`, with or without a `SYS.` prefix, followed by `(` or `;`, and not itself preceded by `.`. PostgreSQL: `RAISE NOTICE`. | the first token of the chain (`sys` when present, else `dbms_output`) |
| MIG010 | low | `FROM` immediately followed by `DUAL`. PostgreSQL: the `FROM` clause is simply omitted. | the `dual` token |
| MIG011 | high | The empty string literal `''` (or the national form `n''`), anywhere. In Oracle `''` **is** `NULL`; in PostgreSQL it is an empty string that is **not** null: a silent change of behavior. A string with content (`'a'`, `''''`) is not flagged. | the token |

### Finding text

* `message` names the Oracle construct that was found (for example ``Oracle NVL() call``).
* `rationale` says what is different in PostgreSQL.
* `fix_hint` gives the PostgreSQL equivalent.

One finding is reported per occurrence. Findings are sorted by line, column and rule id.

## Known false negatives and false positives (accepted, by design)

* **No semantics.** The rules match tokens. They do not know that `nvl` is a user-defined function,
  that a `decode` belongs to another package (a preceding `.` excludes it), or that `rownum` is a
  column name; a quoted identifier such as `"NVL"` is indistinguishable from `nvl` after tokenizing.
* **MIG002**: a `NULL` hidden behind an expression (`decode(x, nvl(y, null), …)`, a variable that
  holds NULL) is not a literal `NULL` and is not mentioned; only the `DECODE` call itself is flagged.
  Arguments are split at commas of the call's own nesting level.
* **MIG003**: `SYSDATE` is flagged wherever it occurs, including uses that port unchanged
  (`to_char(sysdate, …)` is still flagged: the rule asks for a review, not a rewrite). Other
  date/time sources (`CURRENT_DATE`, `LOCALTIMESTAMP`) are not flagged.
* **MIG004**: sequences used through dynamic SQL strings are invisible (strings are opaque). A
  sequence name that is itself `nextval` is not distinguished.
* **MIG005 / MIG006**: `ROWNUM` and `CONNECT BY` inside a dynamic SQL string are not seen.
  `ROWNUM` as a pseudo-column of a qualified reference (`t.rownum`) is skipped on purpose.
* **MIG007**: `(+)` is matched as three tokens, so any `( + )` is flagged, and an outer join written
  inside a dynamic SQL string is not seen.
* **MIG009**: only the package named `DBMS_OUTPUT`. Other output routes (`UTL_FILE`, `HTP`) are out
  of scope, as are references to `dbms_output` that are not calls (`grant execute on dbms_output`).
* **MIG010**: `FROM DUAL` inside a string is not seen, and `FROM SYS.DUAL` is not matched (the `FROM` is
  not immediately followed by `DUAL`). `FROM dual` in a user schema that defines its
  own table `DUAL` is flagged all the same.
* **MIG011**: `''` inside a dynamic SQL string (`'select '''' from t'`) is part of a longer string
  and is not flagged; neither are the quote-delimited empty string `q'[]'` nor expressions that are
  empty at run time (`rpad('', 0)`, `to_char(null)`).
  Both branches of conditional compilation are analyzed.
* **Out of scope (v1):** `BULK COLLECT` / `FORALL`, `EXECUTE IMMEDIATE`, `RAISE_APPLICATION_ERROR`,
  data types, Oracle-supplied packages (`DBMS_LOB`, `DBMS_SQL`, `UTL_FILE`), package state,
  pipelined functions and DDL. Rewriting code is a separate feature; this command only reports.

## Suppression

Identical to the review rules (see [`rules.md`](rules.md#suppression)):
`-- plsql-lens: disable=MIG001,MIG010` suppresses the listed rules on its own line (trailing
comment) or on the next code line (comment alone on a line), and on the header line of a
subprogram/unit it suppresses them for the whole body.

## Command

```bash
plsql-lens migrate PATH [--format table|json|sarif] [-o OUT] [--rules MIG001,MIG002] [--fail-on never|info|low|medium|high]
```

`PATH` is a file or a directory. `--rules` takes a comma-separated list of ids (default: all; an
unknown id is a usage error, exit 2). `--fail-on` and the exit codes are exactly those of
`review`: see [`cli-exit-codes.md`](cli-exit-codes.md). The SARIF output lists the `MIG` rules in
`tool.driver.rules`.
