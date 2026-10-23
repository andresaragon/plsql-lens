.PHONY: help demo-f1 demo-f2 demo-f3 testgen-f3 bench bench-llm test lint
test:
	uv run pytest --cov=plsql_lens --cov-fail-under=85
lint:
	uv run ruff check . && uv run ruff format --check . && uv run mypy
demo-f1:
	rm -rf docs/reports/phase-1 && mkdir -p docs/reports/phase-1
	uv run plsql-lens inventory corpus --format json -o docs/reports/phase-1/inventory.json
	uv run plsql-lens inventory corpus --format mermaid -o docs/reports/phase-1/callgraph.mmd
	uv run python scripts/render_callgraph_md.py docs/reports/phase-1

demo-f2:
	rm -rf docs/reports/phase-2 && mkdir -p docs/reports/phase-2
	uv run plsql-lens review corpus/logger/logger.pkb --format table -o docs/reports/phase-2/review.txt
	uv run plsql-lens review corpus/logger/logger.pkb --format json -o docs/reports/phase-2/review.json
	uv run plsql-lens review corpus/logger/logger.pkb --format sarif -o docs/reports/phase-2/review.sarif
	uv run python scripts/rule_counts.py docs/reports/phase-2/counts.md

demo-f3: ## Run the COMMITTED generated utPLSQL tests on Oracle (Docker, or the GitHub Actions job) and write docs/reports/phase-3/. No LLM calls.
	bash scripts/demo_f3.sh

testgen-f3: ## REGENERATE every utPLSQL test with the LLM. COSTS MONEY (~1.4 USD at Sonnet prices, measured in F3); overwrites tests/generated/.
	uv run plsql-lens testgen-suite --generate --jobs 6

help: ## List the targets
	@grep -E '^[a-z0-9-]+:.*##' $(MAKEFILE_LIST) | sed 's/:.*## /\t/'

bench: ## Regenerate the benchmark splits and every non-LLM table (seeded, deterministic); renders the recorded LLM baseline without calling it
	uv run plsql-lens bench

bench-llm: ## Re-run the LLM-only baseline on the sealed test sample. COSTS MONEY (capped at 2 USD); overwrites docs/benchmarks/llm_baseline/responses.json
	uv run plsql-lens bench-llm --max-usd 2
