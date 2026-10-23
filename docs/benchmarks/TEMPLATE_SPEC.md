# Benchmark template specification

Templates are the *ground truth source* of the benchmark. They are written from `docs/rules.md` only —
never from the rule implementation — by people (or agents) who have not seen what the engine detects.

## File format

`src/plsql_lens/bench/templates/<split>/<RULE>.json`, one file per rule and split:

```json
{
  "rule": "PLL001",
  "split": "dev",
  "defects":   [{"id": "d1", "note": "what makes it a defect", "code": "<PL/SQL subprogram>"}],
  "negatives": [{"id": "n1", "note": "why it is a near-miss that must NOT fire", "code": "<PL/SQL subprogram>"}]
}
```

* `code` is ONE complete subprogram (`PROCEDURE … END name;` or `FUNCTION … END name;`), no `CREATE`,
  no package wrapper, 8–40 lines, valid-looking Oracle PL/SQL, original (not copied from any project).
* Mark each expected finding with a trailing comment `-- @expect` on the exact line given under
  "Location" in `docs/rules.md`. Defects need ≥ 1 marker (PLL007: one marker per occurrence line, and
  at most one occurrence of the literal per line). Negatives have no markers. Markers are stripped
  from the generated source, so the LLM baseline never sees them.
* A defect snippet must trigger ONLY its own rule when it can be avoided (other constructs should be
  clean for the other six rules); a negative snippet is a *near miss*: it looks like the defect but
  the contract of `docs/rules.md` says it must not be reported.

## Placeholders

Tokens of the form `@@name@@` are replaced per generated instance with fresh random values, the same
value for the same token inside one snippet. Use them for everything that should vary:

| Token | Becomes |
|---|---|
| `@@proc@@`, `@@proc2@@` | unique subprogram names |
| `@@tab@@`, `@@tab2@@` | table names |
| `@@col@@`, `@@col2@@` | column names |
| `@@var@@`, `@@var2@@`, `@@var3@@` | local variable names |
| `@@num@@`, `@@num2@@` | a unique 4–5 digit integer (use as the repeated magic number) |
| `@@str@@`, `@@str2@@` | a unique lowercase word with an underscore, to be used INSIDE quotes, e.g. `'@@str@@'` |

Never put a placeholder inside a comment that carries `@expect`. Do not use other `@@` tokens.

## Variety

Each rule gets several *distinct syntactic variants*, not one pattern repeated: vary statement forms,
nesting, keyword case, line breaks, single- vs multi-line statements, function vs procedure, where in
the body the construct sits. The per-rule variant lists to cover are given in the task prompt.
