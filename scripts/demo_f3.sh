#!/usr/bin/env bash
# Run the committed generated tests against a real Oracle and regenerate docs/reports/phase-3/.
# No LLM calls. With Docker: starts Oracle locally. Without Docker: runs the `oracle` GitHub Actions
# workflow (needs `gh` access and the workflow on the default branch, or the current branch pushed).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=docs/reports/phase-3

if docker info >/dev/null 2>&1; then
  echo "Docker found: starting Oracle locally"
  eval "$(docker/up.sh)"
  trap 'docker compose -f docker/compose.yml down -v >/dev/null 2>&1 || true' EXIT
  mkdir -p "$OUT"
  uv run plsql-lens testgen-setup --log "$OUT/setup-targets-full.log" | tee "$OUT/setup-targets.log"
  uv run plsql-lens testgen-suite --report-dir "$OUT"
else
  echo "No Docker: running the 'oracle' workflow on GitHub Actions"
  branch="$(git rev-parse --abbrev-ref HEAD)"
  gh workflow run oracle.yml --ref "$branch"
  sleep 10
  run_id="$(gh run list --workflow oracle.yml --branch "$branch" -L 1 --json databaseId --jq '.[0].databaseId')"
  gh run watch "$run_id" --exit-status
  git fetch origin ci-results/f3
  mkdir -p "$OUT"
  for f in report.json junit.xml setup-targets.log setup-utplsql.log diag-logger.log; do
    git show "origin/ci-results/f3:$f" > "$OUT/$f" 2>/dev/null || true
  done
fi
uv run python scripts/phase3_summary.py "$OUT/report.json" > "$OUT/summary.md"
echo "Report written to $OUT/"
