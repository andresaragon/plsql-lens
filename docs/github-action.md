# GitHub Action

`action.yml` at the repository root is a composite action that runs
`plsql-lens review` and writes the findings as SARIF 2.1.0. It installs the tool from its own
checkout with `uvx --from ${{ github.action_path }}` (PL/SQL Lens is not published to PyPI), so the
version you get is the one the `uses:` reference points at.

## Inputs

| Input | Default | Meaning |
|-------|---------|---------|
| `path` | `.` | File or directory to review, relative to the workspace. |
| `fail-on` | `never` | `never`, `info`, `low`, `medium` or `high`. The step fails (exit 1) when a finding has at least this severity. See [cli-exit-codes.md](cli-exit-codes.md). |
| `rules` | empty | Comma-separated rule ids (`PLL001,PLL002`). Empty runs all rules. |
| `sarif-file` | `plsql-lens.sarif` | Where the SARIF report is written, relative to the workspace. |
| `upload` | `false` | `true` uploads the report with `github/codeql-action/upload-sarif`. |

The SARIF file is written in full even when `fail-on` makes the step fail, so a later step (or the
upload) can still use it.

## Example

```yaml
name: plsql-review
on:
  pull_request:
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: andresaragon/plsql-lens@<full-commit-sha>
        with:
          path: db/packages
          fail-on: high
          sarif-file: plsql-lens.sarif
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: plsql-lens-sarif
          path: plsql-lens.sarif
```

## Using it from another repository

* **Pin to a full commit SHA.** The repository has no tags or releases yet, so there is no `@v1`: replace
  `<full-commit-sha>` in the examples with a commit of `main`.

Inside this repository the action is exercised with `uses: ./` by
`.github/workflows/action-selftest.yml`.

## Uploading to code scanning

Set `upload` to `true` to send the report to GitHub code scanning. The upload step runs even if the
review step failed because of `fail-on`, and is skipped if no SARIF file was written.

```yaml
name: plsql-code-scanning
on:
  push:
    branches: [main]
jobs:
  review:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - uses: andresaragon/plsql-lens@<full-commit-sha>
        with:
          path: db/packages
          fail-on: high
          upload: true
```

Uploading needs code scanning to be available: free on public repositories, but a **private
repository needs GitHub Advanced Security**. That is why `upload` is off by default and the
self-test never enables it.
