from __future__ import annotations

from pathlib import Path

from plsql_lens import parse_file
from plsql_lens.inventory import build_inventory, render_mermaid
from plsql_lens.parser import parse_source
from plsql_lens.parser.lexer import tokenize

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"


def texts(src: str) -> list[str]:
    return [t.text for t in tokenize(src)]


def test_lexer_drops_comments_and_keeps_strings_whole() -> None:
    src = "a := 'it''s -- not a comment'; -- real comment\n/* x ; y */ b := q'[end; it's]';"
    assert texts(src) == [
        "a",
        ":=",
        "'it''s -- not a comment'",
        ";",
        "b",
        ":=",
        "q'[end; it's]'",
        ";",
    ]


def test_lexer_conditional_compilation_keeps_both_branches() -> None:
    assert texts("$IF $$x $THEN a; $ELSE b; $END c;") == ["a", ";", "b", ";", "c", ";"]


def test_lexer_tracks_line_and_column() -> None:
    tok = tokenize("a\n  bb")[1]
    assert (tok.line, tok.col, tok.text) == (2, 3, "bb")


def test_lexer_blanks_sqlplus_lines_but_not_plsql() -> None:
    assert texts("set serveroutput on\nREM hello\nshow errors\nx := 1;") == ["x", ":=", "1", ";"]
    assert "execute" in texts("execute immediate 'x';")


def test_package_spec_params_and_overloads() -> None:
    ir = parse_file(FIXTURES / "shop.pks")
    assert ir.ok
    (unit,) = ir.units
    assert (unit.kind, unit.name) == ("package", "shop")
    add_item, total1, total2 = unit.subprograms
    assert [(p.name, p.mode, p.has_default) for p in add_item.params] == [
        ("p_id", "in", False),
        ("p_qty", "in out", True),
        ("p_note", "out", False),
    ]
    assert add_item.params[0].type == "number"
    assert total1.return_type == "number" and not total1.has_body
    assert total2.return_type == "number"


def test_package_body_nested_subprograms_and_calls() -> None:
    ir = parse_file(FIXTURES / "shop.pkb")
    assert ir.ok, ir.issues
    body = ir.units[0]
    names = [s.name for s in body.subprograms]
    assert names == ["tax_rate", "add_item", "total", "total", "log_it"]
    add_item = body.subprograms[1]
    assert [n.name for n in add_item.nested] == ["helper", "audit"]
    chains = {c.chain for c in add_item.calls}
    assert ("total",) in chains and ("shop", "log_it") in chains
    assert ("log_it",) not in chains  # only inside a comment / strings in the outer body


def test_inventory_resolves_edges_and_ignores_local_and_text_matches() -> None:
    inv = build_inventory([FIXTURES / "shop.pks", FIXTURES / "shop.pkb"])
    keys = {u.key for u in inv.units}
    assert {"package:shop", "procedure:shop.add_item", "function:shop.total"} <= keys
    edges = {(e.caller, e.callee) for e in inv.edges}
    assert ("procedure:shop.add_item", "function:shop.total") in edges
    assert ("procedure:shop.add_item", "procedure:shop.log_it") in edges  # also via nested audit
    assert ("function:shop.total", "function:shop.tax_rate") in edges
    assert ("function:shop.total", "function:shop.total") in edges  # overload collapsed
    assert not any(c == "procedure:shop.add_item" and t.endswith("helper") for c, t in edges)


def test_standalone_trigger_and_type() -> None:
    src = """
    CREATE OR REPLACE PROCEDURE p(x IN NUMBER) IS BEGIN q(x); END;
    /
    CREATE OR REPLACE FUNCTION f RETURN NUMBER IS BEGIN RETURN 1; END f;
    /
    CREATE OR REPLACE TRIGGER trg BEFORE INSERT ON t FOR EACH ROW
    WHEN (new.id IS NOT NULL)
    BEGIN :new.id := f; p(1); END;
    /
    CREATE OR REPLACE TYPE ty AS OBJECT (a NUMBER, MEMBER FUNCTION m RETURN NUMBER);
    /
    CREATE OR REPLACE TYPE BODY ty AS
      MEMBER FUNCTION m RETURN NUMBER IS BEGIN RETURN a; END;
      CONSTRUCTOR FUNCTION ty(self IN OUT NOCOPY ty) RETURN SELF AS RESULT IS BEGIN RETURN; END;
    END;
    /
    """
    ir = parse_source(src)
    assert ir.ok, ir.issues
    assert [(u.kind, u.name) for u in ir.units] == [
        ("procedure", "p"),
        ("function", "f"),
        ("trigger", "trg"),
        ("type", "ty"),
        ("type_body", "ty"),
    ]
    assert ir.units[0].params[0].name == "x"
    assert ir.units[1].return_type == "number"
    assert [s.name for s in ir.units[4].subprograms] == ["m", "ty"]


def test_unterminated_body_reports_issue_but_keeps_partial_ir() -> None:
    ir = parse_source("CREATE PACKAGE BODY b AS PROCEDURE p IS BEGIN NULL;")
    assert not ir.ok
    assert ir.units and ir.units[0].name == "b"


def test_garbage_does_not_raise() -> None:
    assert parse_source("\x00 ((( ;;; END END BEGIN").units == ()


def test_mermaid_output_is_well_formed() -> None:
    inv = build_inventory([FIXTURES / "shop.pks", FIXTURES / "shop.pkb"])
    unit = render_mermaid(inv, "unit")
    assert unit.startswith("flowchart LR")
    assert 'n0["' in unit and "-->" in unit
    pkg = render_mermaid(inv, "package")
    assert "-->" not in pkg  # one package, no inter-package edges
    assert 'n0["shop"]' in pkg


def test_local_variable_types_are_recorded() -> None:
    ir = parse_source(
        "CREATE PROCEDURE p(a_in NUMBER) IS l_n NUMBER; l_s CONSTANT VARCHAR2(10) := 'x';"
        " l_d l_t.col%TYPE; CURSOR c IS SELECT 1 FROM dual; BEGIN NULL; END;"
    )
    unit = ir.units[0]
    assert dict(unit.local_types) == {
        "a_in": "number",
        "l_n": "number",
        "l_s": "varchar2(10)",
        "l_d": "l_t.col%type",
    }
