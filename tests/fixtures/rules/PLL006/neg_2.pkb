-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_rules AS

  FUNCTION is_express(p_code IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF p_code = 'EXP' THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_express;

  FUNCTION bulk_tier(p_qty IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    IF p_qty >= 100 THEN
      RETURN 'BULK';
    END IF;
    RETURN 'SINGLE';
  END bulk_tier;

  PROCEDURE compare_values(p_from IN DATE, p_to IN DATE, p_other IN NUMBER) IS
    l_n NUMBER;
    l_s VARCHAR2(10);
    l_d DATE;
  BEGIN
    l_n := 25;
    l_s := 'ABC';
    l_d := SYSDATE;
    IF l_n > 10 THEN
      DBMS_OUTPUT.PUT_LINE('n is large');
    END IF;
    IF l_n = p_other THEN
      DBMS_OUTPUT.PUT_LINE('n matches');
    END IF;
    IF l_s = 'ABC' THEN
      DBMS_OUTPUT.PUT_LINE('s matches');
    END IF;
    IF l_d > p_from AND l_d < p_to THEN
      DBMS_OUTPUT.PUT_LINE('in range');
    END IF;
  END compare_values;

END pkg_order_rules;
/
