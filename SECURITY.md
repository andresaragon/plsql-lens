# Security policy

## Reporting a vulnerability

Please do not describe a security problem in a public issue or pull request. Use GitHub's private
vulnerability reporting instead: open the [Security tab](https://github.com/andresaragon/plsql-lens/security),
choose **Report a vulnerability** and describe the problem, how to reproduce it and which version or commit you
used. Only the maintainers can see the report.

Please do not publish the details until a fix is available.

## Supported versions

PL/SQL Lens is pre-release software (version 0.1.0, development status "Alpha"). Only the latest
commit of `main` is maintained. The package is not published to PyPI.

## Scope and things to know

- `inventory` and `review` only read PL/SQL source files and print results. `testgen --run` compiles and
  runs LLM-generated utPLSQL tests on the Oracle database you point it at, so use a disposable one.
- The optional LLM and Oracle features take their credentials from environment variables
  (`ANTHROPIC_API_KEY`, and the `PLSQL_LENS_SQLPLUS` command used by `testgen`). Do not commit them.
- `--explain` and the `testgen` and `bench-llm` commands send source code to an LLM provider. Use them
  only on code you are allowed to share with that provider.
