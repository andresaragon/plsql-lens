#!/usr/bin/env bash
# Regenerates the raw tool output of the sample migration audit (docs/demo/oos-utils/).
#
# It clones a third-party project into a temporary directory at a pinned commit, runs the
# read-only commands of plsql-lens on it and writes their raw output to docs/demo/oos-utils/raw/.
# The third-party code is never copied into this repository.
#
# Usage: bash scripts/demo_migration_audit.sh
# Needs: git, uv, network access to github.com.
set -euo pipefail

PROJECT="oos-utils"
URL="https://github.com/OraOpenSource/oos-utils"
SHA="b6217292bc744211eaee9e1d11ca7a0b495bc44d"
SUBDIR="source" # the PL/SQL sources; install/ is a generated bundle of the same packages
LICENSE_FILE="LICENSE"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="$ROOT/docs/demo/$PROJECT/raw"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$RAW"
git init -q "$WORK/src"
git -C "$WORK/src" fetch -q --depth 1 "$URL" "$SHA"
git -C "$WORK/src" checkout -q FETCH_HEAD
if [ "$(git -C "$WORK/src" rev-parse HEAD)" != "$SHA" ]; then
  echo "checked out commit differs from the pinned SHA" >&2
  exit 1
fi

# Run from inside the clone with a relative path, so the paths in the output do not depend on
# the temporary directory.
cd "$WORK/src"
plsql_lens() { uv run --project "$ROOT" --quiet plsql-lens "$@"; }

plsql_lens migrate "$SUBDIR" --format json -o "$RAW/migrate.json"
plsql_lens migrate "$SUBDIR" --format table -o "$RAW/migrate.txt"
plsql_lens inventory "$SUBDIR" --format json -o "$RAW/inventory.json"
plsql_lens inventory "$SUBDIR" --format mermaid -o "$RAW/callgraph.mmd"

# Scope: files the tool analyzes (same selection as the commands above) and their lines.
uv run --project "$ROOT" --quiet python - "$SUBDIR" >"$RAW/scope.json" <<'PY'
import json
import sys
from pathlib import Path

from plsql_lens.inventory import collect_files

files = sorted(collect_files([Path(sys.argv[1])]))
lines = {str(f): len(f.read_text(encoding="utf-8", errors="replace").splitlines()) for f in files}
json.dump({"files": len(files), "lines": sum(lines.values()), "per_file": lines}, sys.stdout,
          indent=2, sort_keys=True)
print()
PY

{
  echo "project: $PROJECT"
  echo "url: $URL"
  echo "commit: $SHA"
  echo "analyzed_path: $SUBDIR"
  echo "license_file: $LICENSE_FILE"
  echo "license_sha256: $(sha256sum "$LICENSE_FILE" | cut -d' ' -f1)"
  echo "license_first_line: $(head -n 1 "$LICENSE_FILE")"
  # The last commit that changed the tool's source: stable while src/ does not change.
  echo "plsql_lens_src_commit: $(git -C "$ROOT" log -1 --format=%H -- src)"
  echo "plsql_lens_version: $(uv run --project "$ROOT" --quiet python -c 'import plsql_lens; print(plsql_lens.__version__)')"
} >"$RAW/meta.txt"

echo "raw output written to $RAW"
