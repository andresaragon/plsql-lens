# Review rules (F2) — contract

Findings are deterministic functions of the IR. The LLM layer never creates or removes findings.
Every finding is reported at the `line` of the construct named under *Location*. A fixture marks an
expected finding with a trailing comment `-- expect: PLLnnn` on that line; a negative fixture has no
marker for the rule under test. Fixture code must be valid-looking PL/SQL written for this repo.

| Rule | Severity | Flags | Location |
|---|---|---|---|
| PLL001 | high | An `EXCEPTION` handler `WHEN OTHERS THEN …` that neither re-raises (`RAISE`, `RAISE x`, `RAISE_APPLICATION_ERROR`) nor logs, nor uses the error (`SQLERRM`, `SQLCODE`, `DBMS_UTILITY.FORMAT_ERROR_*`). Includes handlers that only `NULL;` or only `RETURN` a value. A *logging call* is a call with any dotted part starting with `log`, `audit` or `trace`. | the `WHEN OTHERS` line |
| PLL002 | high | `EXECUTE IMMEDIATE <sql>` or `OPEN c FOR <sql>` where `<sql>` (the tokens before `INTO`/`USING`/`RETURNING`) concatenates (`\|\|`) any operand that is not a string literal or a `DBMS_ASSERT.*` call; or where `<sql>` is a single variable that was assigned by such a concatenation earlier in the same subprogram. | the statement's first line |
| PLL003 | medium | `COMMIT` or `ROLLBACK` (not `ROLLBACK TO savepoint`) lexically inside a `LOOP`/`FOR`/`WHILE` loop of the same subprogram body (also inside an `IF` or handler nested in the loop). | the `COMMIT`/`ROLLBACK` line |
| PLL004 | medium | `SELECT … INTO` (not `BULK COLLECT INTO`) with no handler for `NO_DATA_FOUND`, `TOO_MANY_ROWS` or `OTHERS` in any enclosing block of the same subprogram. Exempt: queries `FROM DUAL`, and aggregate-only select lists (`COUNT/SUM/AVG/MIN/MAX/LISTAGG` anywhere in the select list, including inside expressions such as `NVL(MAX(x), 0) + 1`, but not analytic (`OVER`) nor inside a scalar subquery, and without `GROUP BY` or `HAVING`), which always return one row. | the `SELECT` line |
| PLL005 | medium | A DML statement (`INSERT/UPDATE/DELETE/MERGE`) inside a cursor loop: `FOR r IN (query)`, `FOR r IN cursor_name`, or a plain `LOOP` that contains a `FETCH`. Not flagged: DML under `FORALL`, numeric-range loops (`FOR i IN 1 .. n`). | the DML line |
| PLL006 | low | (a) `TO_DATE`/`TO_TIMESTAMP` called with a single argument (no format mask). (b) A comparison `a <op> b` between two *simple* operands (an identifier or literal that is not part of an arithmetic or `||` expression: `a - b < 3` is not a comparison of simple operands) of different type families (text, number, date) when the identifier's type comes from a parameter or simple local declaration. | the call / the comparison operator line |
| PLL007 | info | The same numeric literal (other than 0 and 1) or string literal (other than empty or a single non-alphanumeric character) occurring 3 or more times in the executable code of one unit (package body, standalone subprogram, trigger). One finding per occurrence. | each occurrence |

## Known false negatives (accepted, by design)
* No type resolution: PLL006 only sees parameters and simple local declarations, simple operands, no
  expressions, no column types in SQL. Anchored types (`%TYPE`) are unknown and skipped.
* PLL007 does not understand context (format masks, SQL text, error codes count as literals); it is
  `info` for that reason. Package-level declarations and constants are not scanned.
* PLL002 cannot see concatenation done in another subprogram or through a function call result.
* PLL005 does not flag numeric-range loops that index collections (the FORALL case).
* PLL004 treats `WHEN OTHERS` as handling (PLL001 covers sloppy `OTHERS`); propagating to the caller
  is not handling.
* Both branches of conditional compilation (`$IF`) are analyzed.

## Suppression
`-- plsql-lens: disable=PLL007,PLL003` suppresses the listed rules on its own line (trailing comment)
or on the next code line (comment alone on a line). On the header line of a subprogram/unit
(`PROCEDURE p IS -- plsql-lens: disable=…`) it suppresses the rules for the whole body.
