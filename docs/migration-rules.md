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
rewrite; **low** = mechanical rewrite; **info** = benign, reported for completeness.

**Severity is per finding.** The *Severity* column is the highest severity a finding of that rule can
have (`Rule.severity`). Every finding carries its own severity (`Finding.severity`), which is the one
the table, JSON and SARIF outputs (the SARIF `level` of each result) and `--fail-on` use. Most rules
give every finding the rule's severity; MIG002, MIG011 and MIG016 decide it from the context of the
match, as described under [Severity by context](#severity-by-context). The number and the location of the
findings do not depend on severity.

| Rule | Severity | Flags | Location |
|---|---|---|---|
| MIG001 | low | A call to `NVL`: the identifier `nvl` followed by `(` and not preceded by `.`. PostgreSQL: `COALESCE`. | the `nvl` token |
| MIG002 | medium | A call to `DECODE`: the identifier `decode` followed by `(` and not preceded by `.`. If a *search argument* is the literal `NULL`, the message says so: `DECODE` matches `NULL` with `NULL`, while `CASE x WHEN NULL` never matches. A search argument is an argument at an even position (2nd, 4th, …) that is followed by a result argument in the same call; the last argument (the default) is not one. An argument is "the literal `NULL`" when its tokens are exactly the identifier `null`. The severity of the finding depends on the search arguments (see below): `medium` at most. | the `decode` token |
| MIG003 | medium | The identifier `SYSDATE` or `SYSTIMESTAMP`, anywhere (strings and comments excluded by the token stream). In Oracle `SYSDATE` is a `DATE`, so `sysdate - d` is a number of days; in PostgreSQL the same expression is an interval (and `+ 1` is an error). The fix hint is static, the same for every finding, and distinguishes two kinds of clock (see below). | the token |
| MIG004 | low | A dotted chain that ends in `.nextval` or `.currval` (`seq.nextval`, `sch.seq.currval`): the identifier `nextval` or `currval` preceded by `.` and, before that, an identifier. PostgreSQL: `nextval('seq')` / `currval('seq')`. | the `nextval` / `currval` token |
| MIG005 | medium | The identifier `ROWNUM` not preceded by `.`. PostgreSQL: `LIMIT`, or `row_number()`. | the token |
| MIG006 | medium | `CONNECT` immediately followed by `BY` (hierarchical query). PostgreSQL: `WITH RECURSIVE`. | the `connect` token |
| MIG007 | medium | Three consecutive tokens `(`, `+`, `)` (the old outer-join operator). PostgreSQL: `LEFT JOIN` / `RIGHT JOIN`. | the `(` |
| MIG008 | high | `PRAGMA` immediately followed by `AUTONOMOUS_TRANSACTION`. PostgreSQL has no equivalent (dblink, `pg_background`, or a redesign). | the `pragma` token |
| MIG009 | low | A call whose dotted chain is `DBMS_OUTPUT.<name>`, with or without a `SYS.` prefix, followed by `(` or `;`, and not itself preceded by `.`. PostgreSQL: `RAISE NOTICE`. | the first token of the chain (`sys` when present, else `dbms_output`) |
| MIG010 | low | `FROM` immediately followed by `DUAL`. PostgreSQL: the `FROM` clause is simply omitted. | the `dual` token |
| MIG011 | high | The empty string literal `''` (or the national form `n''`), anywhere. In Oracle `''` **is** `NULL`; in PostgreSQL it is an empty string that is **not** null: a silent change of behavior. A string with content (`'a'`, `''''`) is not flagged. The severity of the finding depends on where the `''` is (see below): `high` at most. | the token |
| MIG012 | medium | `BULK` immediately followed by `COLLECT` (`BULK COLLECT INTO`, also in `FETCH ... BULK COLLECT` and `EXECUTE IMMEDIATE ... BULK COLLECT`). PostgreSQL: `array_agg()` / `SELECT ... INTO` an array, or a `FOR` loop. | the `bulk` token |
| MIG013 | medium | The identifier `FORALL`, anywhere. PostgreSQL: a loop, or better one set statement (`INSERT ... SELECT unnest(...)`). | the token |
| MIG014 | medium | `EXECUTE` immediately followed by `IMMEDIATE` (dynamic SQL). **The SQL text is not analyzed**: it lives in a string or a variable, and the message says so. PostgreSQL: `EXECUTE format(...) USING ...`; the bind markers `:1` / `:name` become `$1`. | the `execute` token |
| MIG015 | medium | A call to `RAISE_APPLICATION_ERROR`: the identifier `raise_application_error` followed by `(` and not preceded by `.`. PostgreSQL: `RAISE EXCEPTION ... USING ERRCODE`; the error numbers -20000..-20999 and the handlers that compare `SQLCODE` do not carry over by themselves. | the `raise_application_error` token |
| MIG016 | high | A dotted chain whose first element, after an optional `SYS.`, is `DBMS_LOB`, `DBMS_SQL` or `UTL_FILE`, followed by `.` and an identifier (`utl_file.fopen(...)`, `sys.dbms_lob.substr(...)`, `utl_file.file_type`), and not itself preceded by `.`. The severity of the finding depends on the package (see below): `high` at most. | the first token of the chain (`sys` when present, else the package name), as in MIG009 |
| MIG017 | medium | The identifier `PIPELINED`, anywhere (in practice the header of a function, in its specification and again in its body). PostgreSQL: `RETURNS SETOF` / `RETURNS TABLE` with `RETURN NEXT` / `RETURN QUERY`; `PIPE ROW` disappears. | the token |

### Severity by context

The severity of a MIG002 or MIG011 finding is fixed by these definitions; the findings themselves
(how many, where) are exactly those of the table above.

**MIG011**, from the tokens around the `''` token:

| Context | Severity |
|---|---|
| The token before the `''`, or the token after it, is `\|\|` (a concatenation: `x \|\| ''`, `'' \|\| x`). | `info` |
| The `''` is the whole **third argument** of a call to `replace(` or `regexp_replace(` (the replacement; further arguments may follow), the function name not preceded by `.`. | `medium` |
| Anywhere else. | `high` |

A concatenation with `''` gives the same result on both databases (`'abc' || ''` is `abc`, and
`NULL || ''` is NULL), so it is the only strictly benign context. An empty replacement behaves the
same only while the result is not empty (`regexp_replace('abc','b','')` is `ac` on both, but
`regexp_replace('abc','^.*$','')` and `replace('a','a','')` are NULL on Oracle and `''` on
PostgreSQL); whether the result can become empty cannot be known statically, hence `medium`. If the
`''` is next to a `||` it is `info` whatever else surrounds it.

**MIG002**, from the search arguments (the 2nd, 4th, … argument that is followed by a result):

| Search arguments | Severity |
|---|---|
| All are non-null literals: a number or a string, with an optional sign. | `low` |
| At least one is anything else: a column, an expression, a call or the literal `NULL`. | `medium` |

With only non-null literal search values a simple `CASE x WHEN lit …` is exact. Otherwise a search
value may be NULL at run time, and `DECODE` matches `NULL` with `NULL`, also between two columns,
which a simple `CASE` never does: a naive rewrite silently changes the result. When the finding is
`medium` the message says so.

**MIG016**, from the package of the chain (the first element after an optional `SYS.`):

| Package | Severity | Why |
|---|---|---|
| `DBMS_SQL` | `high` | No equivalent: PostgreSQL has no cursor-number API for dynamic SQL; the code has to be redesigned with `EXECUTE`. |
| `UTL_FILE` | `high` | No equivalent: PL/pgSQL cannot read or write server files without extensions. |
| `DBMS_LOB` | `medium` | Large values become `bytea` / `text` and the calls become string or binary functions: a manual rewrite. |

### Finding text

* `message` names the Oracle construct that was found (for example ``Oracle NVL() call``); a MIG002
  finding of severity `medium` also explains the NULL matching of `DECODE`.
* `rationale` says what is different in PostgreSQL.
* `fix_hint` gives the PostgreSQL equivalent.

For MIG012–MIG017 the equivalents are **orientation, not a rewrite**: these rules only detect and
explain, they do not need a database, and `rewrite.py` does not touch these constructs. Each message
is one sentence on what changes and one on what to do in PostgreSQL. The message of MIG014 says that
the dynamic SQL is not analyzed; the message of MIG016 names the package.

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
  The fix hint tells the transaction clock from the real clock. In PostgreSQL `CURRENT_TIMESTAMP`,
  `LOCALTIMESTAMP` and `CURRENT_DATE` return the start time of the current transaction, and
  `clock_timestamp()` returns the real time, which changes even within one statement (PostgreSQL
  documentation, *Date/Time Functions and Operators*, *Current Date/Time*; this is a reading of the
  documentation, not something this repository ran). So the hint must say: use
  `CURRENT_TIMESTAMP`, `LOCALTIMESTAMP` or `CURRENT_DATE` for "the time of the transaction", and
  `clock_timestamp()` when the code waits, measures elapsed time or re-reads the clock several times
  inside one transaction. A busy-wait loop that re-reads `SYSTIMESTAMP` until a deadline would never
  end if it were rewritten with `CURRENT_TIMESTAMP`. The hint is the same text for every MIG003
  finding: the rule does not detect loops, subtractions or any other context, and the number, the
  location and the severity of its findings do not depend on it.
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
* **MIG012**: a `BULK COLLECT` inside a dynamic SQL string is not seen. `bulk` not followed by
  `collect` (a variable `x.bulk`, `bulk_size`) is not flagged. The clause is flagged wherever it is,
  whether in a `SELECT ... BULK COLLECT INTO`, a `FETCH` or a `RETURNING ... BULK COLLECT INTO`; the
  rule does not tell them apart or look at `LIMIT`.
* **MIG013**: every `FORALL` is flagged, with no look at its body, `SAVE EXCEPTIONS` or
  `SQL%BULK_ROWCOUNT`, which also need a manual port. `forall_count` is a different identifier.
* **MIG014**: the rule does not know what is inside the dynamic SQL (a literal, a concatenation or a
  variable): Oracle constructs in it (`NVL`, `ROWNUM`, a `''` …) are not reported by the other rules
  either. `EXECUTE` alone (`dbms_sql.execute(c)`, `GRANT EXECUTE`) is not flagged. `OPEN ... FOR
  <string>` and `DBMS_SQL` are other dynamic-SQL routes: the first is not covered, the second by MIG016.
* **MIG015**: only the unqualified name: `pkg.raise_application_error(` (and `standard.` or
  `sys.` qualified calls) is skipped, as is a local procedure that wraps the call. The rule does not
  look at the error number, so it does not tell -20000..-20999 from an invalid one, nor does it find
  the handlers that compare `SQLCODE` or `SQLERRM`; those need a manual review.
* **MIG016**: only the three packages named. Other Oracle-supplied packages (`DBMS_UTILITY`,
  `DBMS_CRYPTO`, `UTL_HTTP`, …) are not covered. A local synonym of the package or a variable of type
  `UTL_FILE.FILE_TYPE` used through another name is not seen, but the declaration of the variable is
  (`utl_file.file_type`). A reference without a following `.identifier` (`grant execute on dbms_lob`)
  is not flagged. Unlike MIG009, a call is not required: a type or a constant of the package is also a
  hit. The severity depends on the package, not on the member called (`dbms_lob.getlength` is `medium`
  even if it ports with `length()`).
* **MIG017**: the identifier is flagged in the package specification and again in the body, so one
  function gives two findings. `PIPE ROW` statements are not flagged apart from it (they go away with
  the rewrite), nor are the collection types the function returns.
* **Out of scope (v1):** data types, package state and DDL. Rewriting code is a separate feature; this
  command only reports. The F5 constructs `BULK COLLECT` / `FORALL`, `EXECUTE IMMEDIATE`,
  `RAISE_APPLICATION_ERROR`, the packages `DBMS_LOB`, `DBMS_SQL` and `UTL_FILE` and pipelined
  functions are covered by MIG012–MIG017 (detection only); their dynamic SQL text is not analyzed.

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
