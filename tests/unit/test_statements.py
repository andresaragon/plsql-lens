from __future__ import annotations

from plsql_lens.parser import Stmt, parse_source


def body_of(src: str) -> tuple[Stmt, ...]:
    ir = parse_source(src)
    assert ir.ok, ir.issues
    return ir.units[0].body


def kinds(src: str) -> list[tuple[str, tuple[str, ...]]]:
    return [(s.kind, s.context) for s in body_of(src)]


def wrap(inner: str) -> str:
    return f"CREATE OR REPLACE PROCEDURE p IS BEGIN {inner} END p;"


def test_statement_kinds_at_top_level() -> None:
    src = wrap(
        "x := 1; SELECT a INTO x FROM t; INSERT INTO t VALUES (1); EXECUTE IMMEDIATE 'x';"
        " COMMIT; log_it('a'); NULL; RETURN;"
    )
    assert [k for k, _ in kinds(src)] == [
        "assign",
        "select_into",
        "dml",
        "execute_immediate",
        "commit",
        "call",
        "null",
        "return",
    ]


def test_loop_context_and_headers() -> None:
    src = wrap("FOR r IN (SELECT 1 FROM d) LOOP UPDATE t SET a = 1; END LOOP; COMMIT;")
    assert kinds(src) == [("for_loop", ()), ("dml", ("loop",)), ("commit", ())]


def test_while_and_plain_loop() -> None:
    src = wrap("WHILE a < 3 LOOP a := a + 1; END LOOP; LOOP EXIT; END LOOP;")
    assert [k for k, _ in kinds(src)] == ["while_loop", "assign", "loop", "exit"]


def test_if_branches_and_case_statement() -> None:
    src = wrap(
        "IF a THEN x := 1; ELSIF b THEN x := 2; ELSE x := 3; END IF;"
        " CASE a WHEN 1 THEN x := 1; ELSE x := 2; END CASE;"
    )
    ctx = [(k, c) for k, c in kinds(src)]
    assert ctx[0] == ("if", ())
    assert ("assign", ("if",)) in ctx
    assert ("assign", ("case",)) in ctx
    assert [k for k, _ in ctx].count("assign") == 5


def test_case_expression_does_not_split_or_open_scope() -> None:
    src = wrap("x := CASE WHEN a > 1 THEN 1 ELSE 2 END; COMMIT;")
    assert kinds(src) == [("assign", ()), ("commit", ())]


def test_exception_handlers_with_names() -> None:
    src = wrap(
        "x := 1; EXCEPTION WHEN no_data_found OR too_many_rows THEN NULL;"
        " WHEN OTHERS THEN ROLLBACK; RAISE;"
    )
    assert kinds(src) == [
        ("assign", ()),
        ("handler", ()),
        ("null", ("handler:no_data_found,too_many_rows",)),
        ("handler", ()),
        ("rollback", ("handler:others",)),
        ("raise", ("handler:others",)),
    ]


def test_nested_block_and_declare() -> None:
    src = wrap(
        "BEGIN NULL; EXCEPTION WHEN OTHERS THEN NULL; END; DECLARE v NUMBER; BEGIN v := 1; END;"
    )
    got = kinds(src)
    assert ("null", ("begin", "handler:others")) in got
    assert ("assign", ("begin",)) in got


def test_forall_and_open_for_and_bulk() -> None:
    src = wrap(
        "FORALL i IN 1 .. 3 INSERT INTO t VALUES (a(i)); OPEN c FOR 'select 1';"
        " SELECT a BULK COLLECT INTO arr FROM t;"
    )
    got = body_of(src)
    assert [s.kind for s in got] == ["forall", "open_for", "select_bulk"]


def test_labels_and_locations() -> None:
    src = "CREATE PROCEDURE p IS BEGIN\n  <<top>>\n  COMMIT;\nEND;"
    (stmt,) = body_of(src)
    assert stmt.kind == "commit" and stmt.line == 3


def test_subprogram_and_trigger_bodies_have_statements() -> None:
    ir = parse_source(
        "CREATE PACKAGE BODY b AS PROCEDURE q IS BEGIN COMMIT; END; BEGIN NULL; END b;"
        " CREATE TRIGGER t BEFORE INSERT ON x BEGIN NULL; END;"
    )
    pkg, trg = ir.units
    assert [s.kind for s in pkg.subprograms[0].body] == ["commit"]
    assert [s.kind for s in pkg.body] == ["null"]
    assert [s.kind for s in trg.body] == ["null"]


def test_block_ids_distinguish_sibling_blocks_and_tie_handlers_to_their_block() -> None:
    src = wrap(
        "BEGIN a := 1; EXCEPTION WHEN no_data_found THEN NULL; END; BEGIN b := 2; END; c := 3;"
    )
    a, h, _n, b, c = body_of(src)
    assert a.blocks == h.blocks == (0, 1)
    assert b.blocks == (0, 2)
    assert c.blocks == (0,)
