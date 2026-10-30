# CLI exit codes

## `plsql-lens review`

| Code | Meaning |
|------|---------|
| 0 | Review finished and no finding reached the `--fail-on` threshold (always 0 with `--fail-on never`, the default). |
| 1 | At least one finding has severity >= the `--fail-on` threshold. |
| 2 | Incorrect usage (invalid option or value, unknown rule, missing path), reported by Typer. |

### `--fail-on {never,info,low,medium,high}`

Severities are ordered `info < low < medium < high`. The threshold is inclusive:
`--fail-on medium` fails on `medium` and `high` findings, and passes on `info` and `low` ones.

The default is `never`, which keeps the behavior from before the option existed: the exit
code is 0 whatever the findings are, and the output is unchanged.

The output (stdout or the `-o` file, in any `--format`) is written in full before the
process exits, so a failing run still leaves a valid report for the pipeline to archive.

```bash
plsql-lens review src/ --format sarif -o review.sarif --fail-on high
```
