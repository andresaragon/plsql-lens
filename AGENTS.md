# AGENTS.md

Context for coding agents. The source of truth is [CONTRIBUTING.md](CONTRIBUTING.md) (checks, frozen files, costs),
[SPEC.md](SPEC.md) (scope and decisions) and [docs/rules.md](docs/rules.md) (the review rules' contract). If this file
contradicts the repo, the repo wins. This repository is **public**.

## What it is
PL/SQL Lens: a Python 3.11+ library and CLI (`src/plsql_lens/`: `parser`, `inventory`, `rules`, `migrate`, `testgen`, `llm`,
`bench`, `cli.py`) managed with [uv](https://docs.astral.sh/uv/). Tests live in `tests/` (`unit`, `acceptance`, `differential`,
`heldout`, `integration`, `robustness`).

## Commands
Run them with `uv run` from the repository root (these are exactly the CI checks, Python 3.11 and 3.13):
```bash
uv sync
uv run ruff check .
uv run ruff format --check .
uv run mypy                                          # strict, src/ only
uv run pytest --cov=plsql_lens --cov-fail-under=85   # coverage of src/ must stay >= 85 %
```
`make lint` and `make test` wrap them. Verified clean on `main` (ruff, format, mypy) when this file was written.

A change starts with a failing test that states the expected behavior.

## Do not touch without saying so
- **Frozen files:** `src/plsql_lens/parser/`, `src/plsql_lens/rules/`, `docs/rules.md` and the sealed benchmark data
  (`docs/benchmarks/seal.json`). `tests/unit/test_external_frozen.py` pins their hashes; a change fails that test on purpose.
  Only change them if the change is meant to break the seal, and say so in the pull request.
- **Commands that cost money:** `make bench-llm`, `make testgen-f3` and `plsql-lens review --explain` with a real provider
  call an LLM and are billed. Never run them unprompted. Tests use the `fake` provider with recorded responses.
- **Credentials:** never commit them; the optional LLM and Oracle features read environment variables.

## CI jobs that are not part of the default run
`oracle`, `postgres`, `differential` and `robustness` are integration or fuzzing jobs (Oracle Free / PostgreSQL containers)
triggered by `workflow_dispatch` or by `feat/f3-*` / `feat/f5-*` branches. Tests marked `integration` are excluded by
default (`-m 'not integration'`). `tests/unit/test_packaging.py` builds the package and needs `uv` and network access.

## Commits
Use the GitHub noreply identity, not a personal email: export `GIT_AUTHOR_NAME`/`GIT_COMMITTER_NAME` and
`GIT_AUTHOR_EMAIL`/`GIT_COMMITTER_EMAIL` (`16310427+andresaragon@users.noreply.github.com`) before committing on a machine
whose git config has a personal address. Do not rewrite published history.
