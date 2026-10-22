-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_price_lookup AS

  PROCEDURE show_price(p_product_id IN NUMBER) IS
    v_price NUMBER;
  BEGIN
    SELECT unit_price -- expect: PLL004
      INTO v_price
      FROM product
     WHERE product_id = p_product_id;
    DBMS_OUTPUT.PUT_LINE('Price: ' || v_price);
  END show_price;

  FUNCTION customer_name(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
    v_name VARCHAR2(100);
  BEGIN
    SELECT full_name INTO v_name FROM customer WHERE customer_id = p_customer_id; -- expect: PLL004
    RETURN v_name;
  END customer_name;

  PROCEDURE log_lookup(p_product_id IN NUMBER) IS
  BEGIN
    pkg_price_audit.record_lookup(p_product_id);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      NULL;
  END log_lookup;

END pkg_price_lookup;
/
