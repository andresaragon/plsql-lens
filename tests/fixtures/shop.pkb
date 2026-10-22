-- Written for this repo. Tricky lexing: comments, strings, q-quotes, nested subprograms, CASE.
CREATE OR REPLACE PACKAGE BODY shop AS
  FUNCTION tax_rate RETURN NUMBER IS
  BEGIN
    RETURN 0.2; -- end; begin
  END tax_rate;

  PROCEDURE add_item(p_id IN NUMBER, p_qty IN OUT NOCOPY NUMBER DEFAULT 1, p_note OUT VARCHAR2) IS
    l_msg VARCHAR2(100) := 'call log_it; and END;';
    PROCEDURE helper IS BEGIN NULL; END helper;
    PROCEDURE audit(p_text VARCHAR2) IS BEGIN log_it(p_text); END;
  BEGIN
    helper;
    audit('x');
    IF p_qty > c_max THEN
      p_note := CASE WHEN p_qty > 100 THEN 'big' ELSE 'ok' END;
    END IF;
    FOR i IN 1 .. 3 LOOP
      p_qty := p_qty + total(p_id);
    END LOOP;
    /* log_it('not a call') */
    BEGIN
      shop.log_it(q'[it's END; log_it(1)]');
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END add_item;

  FUNCTION total(p_order NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN total(p_order, tax_rate);
  END;

  FUNCTION total(p_order NUMBER, p_tax NUMBER) RETURN NUMBER DETERMINISTIC IS
  BEGIN
    RETURN p_order * (1 + p_tax);
  END;

  PROCEDURE log_it(p_text VARCHAR2) IS
  BEGIN
    $IF $$debug $THEN dbms_output.put_line(p_text); $END
    NULL;
  END;
END shop;
/
