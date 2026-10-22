-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_codes AS

  FUNCTION is_priority(p_code IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF p_code = 10 THEN -- expect: PLL006
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_priority;

  FUNCTION describe_qty(p_qty IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    IF p_qty > 'MAX' THEN -- expect: PLL006
      RETURN 'too many';
    END IF;
    RETURN 'ok';
  END describe_qty;

  PROCEDURE route_order(p_code IN VARCHAR2, p_region IN VARCHAR2) IS
  BEGIN
    IF p_region = 'EU' THEN
      DBMS_OUTPUT.PUT_LINE('route eu ' || p_code);
    ELSIF p_region = 'US' THEN
      DBMS_OUTPUT.PUT_LINE('route us ' || p_code);
    END IF;
  END route_order;

  FUNCTION is_big_batch(p_size IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    IF p_size >= 250 THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_big_batch;

END pkg_order_codes;
/
