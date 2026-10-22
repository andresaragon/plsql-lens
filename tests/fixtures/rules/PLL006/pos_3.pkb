-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_invoice_checks AS

  PROCEDURE check_due(p_ref IN VARCHAR2) IS
    l_n NUMBER;
    l_s VARCHAR2(10);
    l_d DATE;
  BEGIN
    l_n := 5;
    l_s := p_ref;
    l_d := SYSDATE;
    IF l_d > '2025-01-01' THEN -- expect: PLL006
      DBMS_OUTPUT.PUT_LINE('late');
    END IF;
    IF l_n = l_s THEN -- expect: PLL006
      DBMS_OUTPUT.PUT_LINE('ref is numeric');
    END IF;
  END check_due;

  PROCEDURE check_limit(p_limit IN NUMBER) IS
    l_cap NUMBER;
    l_tag VARCHAR2(10);
  BEGIN
    l_cap := p_limit * 2;
    l_tag := 'CAP';
    IF l_cap = 'NONE' THEN -- expect: PLL006
      DBMS_OUTPUT.PUT_LINE('no cap');
    END IF;
    IF l_tag = 'CAP' THEN
      DBMS_OUTPUT.PUT_LINE('capped at ' || l_cap);
    END IF;
  END check_limit;

END pkg_invoice_checks;
/
