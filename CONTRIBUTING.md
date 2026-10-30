# Contributing

PL/SQL Lens is a Python (3.11 or newer) library and CLI managed with [uv](https://docs.astral.sh/uv/).
[`SPEC.md`](SPEC.md) describes the scope and [`docs/rules.md`](docs/rules.md) the review rules'
contract.

## Set up

```bash
uv sync
```

## Checks

Every change must pass the four checks that CI runs (`.github/workflows/ci.yml`, Python 3.11 and 3.13):

```bash
uv run ruff check .
uv run ruff format --check .
uv run mypy
uv run pytest --cov=plsql_lens --cov-fail-under=85
```

`make lint` runs the first three and `make test` runs the fourth. Line coverage of `src/` must stay
at or above 85 %.

Tests are written first: a change starts with a failing test that states the expected behavior.

## Other test suites

- Tests marked `integration` need an Oracle container and are excluded from the default run.
- `tests/robustness/` fuzzes the parser with seeded mutations. It is excluded from the default run:
  `uv run pytest tests/robustness -m robustness`.
- `tests/unit/test_packaging.py` builds the package and installs it in a clean virtual environment; it
  is skipped when `uv` or network access is missing.

## Frozen files

`src/plsql_lens/parser/`, `src/plsql_lens/rules/` and `docs/rules.md` are frozen by the F4b
external-split evaluation: `tests/unit/test_external_frozen.py` pins their hashes, so any change fails
that test. The sealed benchmark data (`docs/benchmarks/seal.json`) is enforced the same way. Do not
change them unless the change is meant to break the seal, and say so in the pull request.

## Commands that cost money

`make bench-llm`, `make testgen-f3` and `plsql-lens review --explain` with a real provider call an
LLM and are billed. Tests never call one: they use the `fake` provider with recorded responses.

## Credentials

Do not commit credentials: the optional LLM and Oracle features read them from environment variables.
