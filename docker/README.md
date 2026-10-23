# Oracle for the F3 tests

* `compose.yml` — Oracle Database Free (`gvenzl/oracle-free:23.26.3-slim`). The image is pulled from
  Docker Hub under Oracle's own license terms; this repository does not redistribute it.
* `setup.sh` — installs utPLSQL v3.1.14 (SHA-256 verified) and creates the `PLLT` schema.
* `up.sh` — local helper: `eval "$(docker/up.sh)"` starts everything with a random password and exports
  `ORACLE_PASSWORD` and `PLSQL_LENS_SQLPLUS`.

Then:

```bash
uv run plsql-lens testgen-setup           # installs Logger, HR sample, the repo's own packages
uv run plsql-lens testgen-suite           # runs the committed tests, writes docs/reports/phase-3/
```

Passwords come from the environment only (`ORACLE_PASSWORD`, see `.env.example`). Without Docker, run the
same steps in GitHub Actions: `.github/workflows/oracle.yml` (`workflow_dispatch`).
