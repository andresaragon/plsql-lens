-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_customer_read AS

  FUNCTION customer_name(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
    v_name VARCHAR2(100);
  BEGIN
    SELECT full_name
      INTO v_name
      FROM customer
     WHERE customer_id = p_customer_id;
    RETURN v_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'UNKNOWN';
  END customer_name;

  FUNCTION customer_tier(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
    v_tier VARCHAR2(10);
  BEGIN
    BEGIN
      SELECT tier_code INTO v_tier FROM customer_tier WHERE customer_id = p_customer_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_tier := 'BASIC';
    END;
    RETURN v_tier;
  END customer_tier;

  FUNCTION customer_region(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
    v_region VARCHAR2(30);
  BEGIN
    BEGIN
      SELECT region_name INTO v_region FROM customer_region WHERE customer_id = p_customer_id;
      RETURN v_region;
    END;
  EXCEPTION
    WHEN TOO_MANY_ROWS THEN
      RETURN 'MULTIPLE';
  END customer_region;

END pkg_customer_read;
/
