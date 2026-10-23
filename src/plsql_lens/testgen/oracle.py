"""Oracle access through a configurable ``sqlplus`` command (no Python driver dependency)."""

from __future__ import annotations

import re
import subprocess
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True, slots=True)
class CompileResult:
    ok: bool
    errors: str


class Oracle(Protocol):
    def compile(self, code: str, test_package: str) -> CompileResult: ...

    def run_tests(self, test_package: str) -> str:
        """Run the package with utPLSQL and return JUnit XML."""
        ...


class OracleError(RuntimeError):
    pass


_PREAMBLE = (
    "set define off\nset sqlblanklines on\nset feedback off\nwhenever oserror exit failure\n"
)


class SqlplusOracle:
    """Runs scripts by piping them into a shell command that starts sqlplus.

    ``command`` comes from the environment (PLSQL_LENS_SQLPLUS), e.g.
    ``docker exec -i plsql-lens-oracle sqlplus -s -L tgt/"$ORACLE_PASSWORD"@//localhost/FREEPDB1``.
    Credentials stay in environment variables referenced by the command.
    """

    def __init__(self, command: str, timeout: int = 600) -> None:
        self.command, self.timeout = command, timeout

    def run_script(self, script: str) -> str:
        try:
            proc = subprocess.run(
                self.command,
                shell=True,  # noqa: S602 - command is operator-supplied configuration
                input=_PREAMBLE + script + "\nexit\n",
                capture_output=True,
                text=True,
                timeout=self.timeout,
            )
        except (OSError, subprocess.TimeoutExpired) as e:
            raise OracleError(f"sqlplus failed: {e}") from e
        if proc.returncode != 0:
            raise OracleError(f"sqlplus exited {proc.returncode}: {proc.stderr.strip()[:500]}")
        return proc.stdout

    def compile(self, code: str, test_package: str) -> CompileResult:
        name = test_package.upper()
        probe = (
            "\nset heading off\nset pagesize 0\nset linesize 2000\n"
            f"select 'PLL_ERR|' || type || '|' || line || ':' || position || ' ' || text "
            f"from user_errors where name = '{name}' order by type, sequence;\n"
            f"select 'PLL_STATUS|' || object_type || '|' || status from user_objects "
            f"where object_name = '{name}';\n"
        )
        out = self.run_script(code + probe)
        errors = [ln[len("PLL_ERR|") :] for ln in out.splitlines() if ln.startswith("PLL_ERR|")]
        other = [
            ln
            for ln in out.splitlines()
            if re.match(r"^(ORA|SP2|PLS)-\d+", ln) and not ln.startswith("PLL_")
        ]
        valid_body = "PLL_STATUS|PACKAGE BODY|VALID" in out
        if errors or other or not valid_body:
            detail = errors + other
            return CompileResult(False, "\n".join(detail) or "package body is missing or INVALID")
        return CompileResult(True, "")

    def run_tests(self, test_package: str) -> str:
        script = (
            "set heading off\nset pagesize 0\nset linesize 32767\nset long 10000000\n"
            "set trimspool on\nset serveroutput off\n"
            f"select * from table(ut.run('{test_package}', ut_junit_reporter()));\n"
        )
        out = self.run_script(script)
        start, end = out.find("<?xml"), out.rfind(">")
        if start < 0:
            start = out.find("<testsuites")
        if start < 0 or end < start:
            raise OracleError("utPLSQL returned no JUnit XML: " + out.strip()[:500])
        return out[start : end + 1]
