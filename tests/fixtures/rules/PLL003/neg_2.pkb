-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_lines AS

  PROCEDURE apply_lines(p_order_id IN NUMBER) IS
  BEGIN
    FOR r IN (SELECT line_id FROM order_line WHERE order_id = p_order_id) LOOP
      SAVEPOINT sp_line;
      BEGIN
        pkg_order_api.apply_line(r.line_id);
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          ROLLBACK TO SAVEPOINT sp_line;
      END;
    END LOOP;
    COMMIT;
  END apply_lines;

  PROCEDURE apply_discounts(p_order_id IN NUMBER) IS
    v_n PLS_INTEGER := 0;
  BEGIN
    WHILE v_n < 4 LOOP
      v_n := v_n + 1;
      SAVEPOINT sp_discount;
      BEGIN
        pkg_order_api.apply_discount(p_order_id, v_n);
      EXCEPTION
        WHEN VALUE_ERROR THEN
          ROLLBACK TO sp_discount;
      END;
    END LOOP;
  END apply_discounts;

END pkg_order_lines;
/
