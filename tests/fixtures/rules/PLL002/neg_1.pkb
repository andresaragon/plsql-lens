-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_dynamic AS

  PROCEDURE change_status(p_order_id IN NUMBER, p_status IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'UPDATE orders SET status = :s WHERE order_id = :id'
      USING p_status, p_order_id;
  END change_status;

  FUNCTION count_for_customer(p_customer_id IN NUMBER) RETURN NUMBER IS
    v_count NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM orders WHERE customer_id = :c'
      INTO v_count
      USING p_customer_id;
    RETURN v_count;
  END count_for_customer;

  PROCEDURE open_by_status(p_status IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR 'SELECT order_id, total FROM orders WHERE status = :s'
      USING p_status;
  END open_by_status;

  PROCEDURE bump_priority(p_order_id IN NUMBER, p_level IN NUMBER) IS
  BEGIN
    EXECUTE IMMEDIATE 'UPDATE orders SET priority = :p WHERE order_id = :id'
      USING p_level, p_order_id;
  END bump_priority;

END pkg_order_dynamic;
/
