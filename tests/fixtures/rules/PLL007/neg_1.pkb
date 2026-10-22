-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_stock_counts AS

  FUNCTION count_low_items(p_threshold IN NUMBER) RETURN NUMBER IS
    l_count NUMBER := 0;
  BEGIN
    FOR r IN (SELECT qty_on_hand FROM inventory) LOOP
      IF r.qty_on_hand < p_threshold THEN
        l_count := l_count + 1;
      END IF;
    END LOOP;
    IF l_count = 0 THEN
      RETURN 0;
    END IF;
    RETURN l_count;
  END count_low_items;

  FUNCTION next_batch(p_last IN NUMBER) RETURN NUMBER IS
  BEGIN
    IF p_last IS NULL OR p_last < 0 THEN
      RETURN 1;
    END IF;
    RETURN p_last + 1;
  END next_batch;

  PROCEDURE warn_low_stock(p_count IN NUMBER) IS
    l_limit NUMBER;
  BEGIN
    l_limit := 250;
    IF p_count > l_limit THEN
      DBMS_OUTPUT.PUT_LINE('low stock');
    ELSIF p_count > 250 THEN
      DBMS_OUTPUT.PUT_LINE('low stock');
    END IF;
  END warn_low_stock;

END pkg_stock_counts;
/
