#!/usr/bin/env bash
# Create the target schema (PLLT) and install utPLSQL (pinned release, checksum verified).
# Needs: a running plsql-lens-oracle container (docker compose -f docker/compose.yml up -d --wait)
# and ORACLE_PASSWORD in the environment (the SYS password the container was started with).
set -euo pipefail

: "${ORACLE_PASSWORD:?set ORACLE_PASSWORD (the password the container was started with)}"
CONTAINER="${CONTAINER:-plsql-lens-oracle}"
PDB="${PDB:-FREEPDB1}"
UT_VERSION="v3.1.14"
# SHA-256 of utPLSQL.zip for the release above (upstream publishes no checksum; this pins the bytes we tested).
UT_SHA256="d98a29f93266e2477c83ffda7e997073bd1c7aa9895e117e406a1003e40c5477"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/utPLSQL.zip" \
  "https://github.com/utPLSQL/utPLSQL/releases/download/${UT_VERSION}/utPLSQL.zip"
echo "${UT_SHA256}  ${work}/utPLSQL.zip" | sha256sum -c -
unzip -q "$work/utPLSQL.zip" -d "$work"
docker cp "$work/utPLSQL" "${CONTAINER}:/tmp/utPLSQL"
# docker cp creates root-owned files; the installer writes scratch files next to its scripts.
docker exec -u 0 "$CONTAINER" chown -R oracle:oinstall /tmp/utPLSQL

# utPLSQL owner (UT3), public synonyms/grants, and the schema that holds the targets and tests.
docker exec -i -w /tmp/utPLSQL/source "$CONTAINER" \
  sqlplus -s -L "sys/${ORACLE_PASSWORD}@//localhost/${PDB} as sysdba" <<SQL
whenever sqlerror exit failure rollback
@create_utplsql_owner.sql ut3 ${ORACLE_PASSWORD} users
@install.sql ut3
@create_synonyms_and_grants_for_public.sql ut3
create user pllt identified by "${ORACLE_PASSWORD}" default tablespace users quota unlimited on users;
grant create session, create table, create view, create sequence, create procedure,
      create trigger, create type, create synonym, create any context, drop any context to pllt;
exit
SQL
echo "utPLSQL ${UT_VERSION} installed; schema PLLT created."
