"""Regenerate tests/fixtures/migrate/semantics.json: reference results observed on Oracle (F5).

Every case is run on a real Oracle and its result is stored as the truth that a rewrite must
reproduce on PostgreSQL. Each case also carries a hand-written PostgreSQL translation that is only used
here to check the data set itself: a case that is not marked as a divergence must give the same result on
both databases, and one that is marked must differ (its PostgreSQL result is stored as `pg_naive_result`).
Nothing here calls an LLM.

    PLSQL_LENS_SQLPLUS='docker exec -i <oracle> sqlplus -s -L user/password@//localhost/FREEPDB1' \\
    PLSQL_LENS_PSQL='docker exec -i -e PGPASSWORD=<pw> <postgres> psql -X -q -A -t -v ON_ERROR_STOP=1 -U postgres' \\
    python scripts/migrate_semantics.py
"""

import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "tests" / "fixtures" / "migrate" / "semantics.json"
NULL = "<NULL>"
EMPTY = "oracle_empty_string_is_null"
CONCAT = "oracle_concat_ignores_null"

# (id, construct, setup, oracle_sql, hand-written PostgreSQL translation, divergence reason or None)
Case = tuple[str, str, list[str], str, str, str | None]


def seq(name: str, start: int, step: int = 1) -> str:
    return f"create sequence {name} start with {start} increment by {step}"


CASES: list[Case] = [
    ("nvl_01", "nvl", [], "SELECT NVL(NULL, 'x') FROM DUAL", "SELECT COALESCE(NULL, 'x')", None),
    ("nvl_02", "nvl", [], "SELECT NVL('a', 'x') FROM DUAL", "SELECT COALESCE('a', 'x')", None),
    ("nvl_03", "nvl", [], "SELECT NVL(NULL, 5) FROM DUAL", "SELECT COALESCE(NULL, 5)", None),
    (
        "nvl_04",
        "nvl",
        [],
        "SELECT NVL(NVL(NULL, 3), 7) FROM DUAL",
        "SELECT COALESCE(COALESCE(NULL, 3), 7)",
        None,
    ),
    ("nvl_05", "nvl", [], "SELECT NVL(NULL, NULL) FROM DUAL", "SELECT COALESCE(NULL, NULL)", None),
    ("nvl_06", "nvl", [], "SELECT NVL(1 + 2, 0) FROM DUAL", "SELECT COALESCE(1 + 2, 0)", None),
    (
        "nvl_07",
        "nvl",
        [],
        "SELECT NVL(NULLIF(1, 1), 9) FROM DUAL",
        "SELECT COALESCE(NULLIF(1, 1), 9)",
        None,
    ),
    ("nvl_08", "nvl", [], "SELECT NVL('', 'x') FROM DUAL", "SELECT COALESCE('', 'x')", EMPTY),
    (
        "nvl_09",
        "nvl",
        [],
        "SELECT NVL(TRIM('  '), 'blank') FROM DUAL",
        "SELECT COALESCE(TRIM('  '), 'blank')",
        EMPTY,
    ),
    (
        "nvl_10",
        "nvl",
        [],
        "SELECT NVL(SUBSTR('abc', 5), 'e') FROM DUAL",
        "SELECT COALESCE(SUBSTR('abc', 5), 'e')",
        EMPTY,
    ),
    (
        "nvl_11",
        "nvl",
        [],
        "SELECT NVL('abc' || NULL, 'z') FROM DUAL",
        "SELECT COALESCE('abc' || NULL, 'z')",
        CONCAT,
    ),
    (
        "decode_01",
        "decode",
        [],
        "SELECT DECODE(1, 1, 'a', 2, 'b', 'c') FROM DUAL",
        "SELECT CASE 1 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END",
        None,
    ),
    (
        "decode_02",
        "decode",
        [],
        "SELECT DECODE(2, 1, 'a', 2, 'b', 'c') FROM DUAL",
        "SELECT CASE 2 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END",
        None,
    ),
    (
        "decode_03",
        "decode",
        [],
        "SELECT DECODE(3, 1, 'a', 2, 'b', 'c') FROM DUAL",
        "SELECT CASE 3 WHEN 1 THEN 'a' WHEN 2 THEN 'b' ELSE 'c' END",
        None,
    ),
    (
        "decode_04",
        "decode",
        [],
        "SELECT DECODE(3, 1, 'a', 2, 'b') FROM DUAL",
        "SELECT CASE 3 WHEN 1 THEN 'a' WHEN 2 THEN 'b' END",
        None,
    ),
    (
        "decode_05",
        "decode",
        [],
        "SELECT DECODE(NULL, NULL, 'isnull', 'notnull') FROM DUAL",
        "SELECT CASE WHEN NULL IS NULL THEN 'isnull' ELSE 'notnull' END",
        None,
    ),
    (
        "decode_06",
        "decode",
        [],
        "SELECT DECODE(NULL, 1, 'a', 'z') FROM DUAL",
        "SELECT CASE WHEN NULL = 1 THEN 'a' ELSE 'z' END",
        None,
    ),
    (
        "decode_07",
        "decode",
        [],
        "SELECT DECODE('x', 'x', 1, 'y', 2) FROM DUAL",
        "SELECT CASE 'x' WHEN 'x' THEN 1 WHEN 'y' THEN 2 END",
        None,
    ),
    (
        "decode_08",
        "decode",
        [],
        "SELECT DECODE(1 + 1, 2, 'two', 'other') FROM DUAL",
        "SELECT CASE 1 + 1 WHEN 2 THEN 'two' ELSE 'other' END",
        None,
    ),
    (
        "decode_09",
        "decode",
        [],
        "SELECT DECODE(DECODE(1, 1, 2, 3), 2, 'ok', 'no') FROM DUAL",
        "SELECT CASE (CASE 1 WHEN 1 THEN 2 ELSE 3 END) WHEN 2 THEN 'ok' ELSE 'no' END",
        None,
    ),
    (
        "decode_10",
        "decode",
        [],
        "SELECT DECODE(NULL, 1, 'a', NULL, 'n', 'd') FROM DUAL",
        "SELECT CASE WHEN NULL = 1 THEN 'a' WHEN NULL IS NULL THEN 'n' ELSE 'd' END",
        None,
    ),
    (
        "decode_11",
        "decode",
        [],
        "SELECT DECODE('', NULL, 'isnull', 'notnull') FROM DUAL",
        "SELECT CASE WHEN '' IS NULL THEN 'isnull' ELSE 'notnull' END",
        EMPTY,
    ),
    (
        "decode_12",
        "decode",
        [],
        "SELECT DECODE(2, 1, 'a', 2, 'b', 2, 'c') FROM DUAL",
        "SELECT CASE 2 WHEN 1 THEN 'a' WHEN 2 THEN 'b' WHEN 2 THEN 'c' END",
        None,
    ),
    (
        "nextval_01",
        "nextval",
        [seq("f5_s1", 5)],
        "SELECT f5_s1.NEXTVAL FROM DUAL",
        "SELECT nextval('f5_s1')",
        None,
    ),
    (
        "nextval_02",
        "nextval",
        [seq("f5_s2", 10, 5)],
        "SELECT f5_s2.NEXTVAL FROM DUAL",
        "SELECT nextval('f5_s2')",
        None,
    ),
    (
        "nextval_03",
        "nextval",
        [seq("f5_s3", 1)],
        "SELECT f5_s3.NEXTVAL + f5_s3.CURRVAL FROM DUAL",
        "SELECT nextval('f5_s3') + currval('f5_s3')",
        None,
    ),
    (
        "nextval_04",
        "nextval",
        [seq("f5_s4", 100)],
        "SELECT 'id-' || f5_s4.NEXTVAL FROM DUAL",
        "SELECT 'id-' || nextval('f5_s4')",
        None,
    ),
    (
        "nextval_05",
        "nextval",
        [seq("f5_s5", 21)],
        "SELECT f5_s5.NEXTVAL * 2 FROM DUAL",
        "SELECT nextval('f5_s5') * 2",
        None,
    ),
    (
        "nextval_06",
        "nextval",
        [seq("f5_s6", 7)],
        "SELECT F5_S6.nextval FROM dual",
        "SELECT nextval('F5_S6')",
        None,
    ),
    ("from_dual_01", "from_dual", [], "SELECT 1 FROM DUAL", "SELECT 1", None),
    ("from_dual_02", "from_dual", [], "SELECT 'a' || 'b' FROM DUAL", "SELECT 'a' || 'b'", None),
    ("from_dual_03", "from_dual", [], "SELECT 1 + 1 FROM dual", "SELECT 1 + 1", None),
    (
        "from_dual_04",
        "from_dual",
        [],
        "SELECT   2 * 3\nFROM   DUAL",
        "SELECT   2 * 3",
        None,
    ),
    (
        "from_dual_05",
        "from_dual",
        [],
        "SELECT 'x' FROM DUAL WHERE 1 = 1",
        "SELECT 'x' WHERE 1 = 1",
        None,
    ),
    (
        "mixed_01",
        "mixed",
        [],
        "SELECT NVL(NULL, 'x') || DECODE(1, 1, 'a', 'b') FROM DUAL",
        "SELECT COALESCE(NULL, 'x') || CASE 1 WHEN 1 THEN 'a' ELSE 'b' END",
        None,
    ),
    (
        "mixed_02",
        "mixed",
        [seq("f5_s7", 3)],
        "SELECT NVL(f5_s7.NEXTVAL, 0) FROM DUAL",
        "SELECT COALESCE(nextval('f5_s7'), 0)",
        None,
    ),
    (
        "mixed_03",
        "mixed",
        [],
        "SELECT DECODE(NVL(NULL, 2), 2, 'two', 'other') FROM DUAL",
        "SELECT CASE COALESCE(NULL, 2) WHEN 2 THEN 'two' ELSE 'other' END",
        None,
    ),
]


def shell(var: str, script: str) -> str:
    cmd = os.environ.get(var)
    if not cmd:
        sys.exit(f"{var} is not set (see the module docstring)")
    done = subprocess.run(shlex.split(cmd), input=script, capture_output=True, text=True)
    if done.returncode != 0:
        sys.exit(f"{var} failed ({done.returncode}):\n{done.stdout}\n{done.stderr}")
    return done.stdout


def sequences(setup: list[str]) -> list[str]:
    return [m.group(1) for s in setup if (m := re.match(r"create sequence (\w+)", s))]


def oracle(setup: list[str], sql: str) -> str:
    drops = "".join(f"drop sequence {n};\n" for n in sequences(setup))
    script = (
        "set pagesize 0 feedback off heading off verify off linesize 4000 trimspool on echo off\n"
        "whenever sqlerror exit 1\n"
        + "".join(f"{s};\n" for s in setup)
        + f"prompt @@BEGIN\n{sql};\nprompt @@END\n{drops}exit\n"
    )
    out = shell("PLSQL_LENS_SQLPLUS", script)
    body = out.split("@@BEGIN", 1)[1].split("@@END", 1)[0].strip("\n")
    return body.strip() or NULL  # Oracle prints NULL and '' alike: they are the same value


def postgres(setup: list[str], sql: str) -> str:
    drops = "".join(f"drop sequence {n};\n" for n in sequences(setup))
    wrapped = f"select coalesce(cast(x as text), '{NULL}') from ({sql}) t(x)"
    script = "".join(f"{s};\n" for s in setup) + f"{wrapped};\n{drops}"
    return shell("PLSQL_LENS_PSQL", script).strip("\n")


def main() -> None:
    version = oracle([], "select banner_full from v$version FETCH FIRST 1 ROWS ONLY").splitlines()
    version_text = " ".join(version[0].split()) if version else "unknown"
    rows, bad = [], []
    for cid, construct, setup, osql, psql, divergence in CASES:
        want = oracle(setup, osql)
        got = postgres(setup, psql)
        if (got == want) == (divergence is not None):
            bad.append(f"{cid}: oracle={want!r} postgres={got!r} divergence={divergence}")
        row: dict[str, object] = {
            "id": cid,
            "construct": construct,
            "setup": setup,
            "oracle_sql": osql,
            "oracle_result": want,
            "oracle_version": version_text,
        }
        if divergence:
            row["known_divergence"] = {"reason": divergence, "pg_naive_result": got}
        rows.append(row)
    if bad:
        sys.exit("data set is inconsistent:\n" + "\n".join(bad))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"null_marker": NULL, "cases": rows}, indent=2) + "\n")
    print(f"{len(rows)} cases written to {OUT} ({version_text})")


if __name__ == "__main__":
    main()
