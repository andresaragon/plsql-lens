#!/usr/bin/env bash
# Local helper: start Oracle with a throw-away password and print the export lines to use it.
# Usage: eval "$(docker/up.sh)"
set -euo pipefail
ORACLE_PASSWORD="${ORACLE_PASSWORD:-$(openssl rand -hex 12)}"
export ORACLE_PASSWORD
docker compose -f "$(dirname "$0")/compose.yml" up -d --wait --wait-timeout 600 >&2
bash "$(dirname "$0")/setup.sh" >&2
echo "export ORACLE_PASSWORD='${ORACLE_PASSWORD}'"
echo "export PLSQL_LENS_SQLPLUS='docker exec -i plsql-lens-oracle sqlplus -s -L pllt/\"\$ORACLE_PASSWORD\"@//localhost/FREEPDB1'"
