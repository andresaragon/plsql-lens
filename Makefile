.PHONY: demo-f1 test lint
test:
	uv run pytest
lint:
	uv run ruff check . && uv run ruff format --check . && uv run mypy
demo-f1:
	rm -rf docs/reports/phase-1 && mkdir -p docs/reports/phase-1
	uv run plsql-lens inventory corpus --format json -o docs/reports/phase-1/inventory.json
	uv run plsql-lens inventory corpus --format mermaid -o docs/reports/phase-1/callgraph.mmd
	uv run python scripts/render_callgraph_md.py docs/reports/phase-1
