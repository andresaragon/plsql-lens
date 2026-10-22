.PHONY: demo-f1 demo-f2 test lint
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
