-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_dates AS

  FUNCTION parse_ship_date(p_text IN VARCHAR2) RETURN DATE IS
  BEGIN
    RETURN TO_DATE(p_text); -- expect: PLL006
  END parse_ship_date;

  FUNCTION parse_stamp(p_stamp IN VARCHAR2) RETURN TIMESTAMP IS
  BEGIN
    RETURN TO_TIMESTAMP(p_stamp); -- expect: PLL006
  END parse_stamp;

  FUNCTION parse_due_date(p_text IN VARCHAR2) RETURN DATE IS
  BEGIN
    RETURN TO_DATE(p_text, 'YYYY-MM-DD');
  END parse_due_date;

  PROCEDURE set_ship_date(p_order_id IN NUMBER, p_text IN VARCHAR2) IS
    l_date DATE;
  BEGIN
    l_date := TO_DATE(p_text); -- expect: PLL006
    UPDATE orders SET ship_date = l_date WHERE order_id = p_order_id;
  END set_ship_date;

  PROCEDURE show_ship_date(p_order_id IN NUMBER) IS
    l_date DATE;
  BEGIN
    SELECT ship_date INTO l_date FROM orders WHERE order_id = p_order_id;
    DBMS_OUTPUT.PUT_LINE('ships on ' || TO_CHAR(l_date, 'DD-MON-YYYY'));
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('unknown order');
  END show_ship_date;

END pkg_order_dates;
/
