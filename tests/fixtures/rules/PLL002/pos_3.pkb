-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_reports AS

  PROCEDURE open_orders(p_filter IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR 'SELECT order_id, total FROM orders WHERE ' || p_filter; -- expect: PLL002
  END open_orders;

  PROCEDURE open_sorted(p_column IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR -- expect: PLL002
      'SELECT order_id, total FROM orders ORDER BY ' || p_column;
  END open_sorted;

  PROCEDURE open_recent(p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR
      SELECT order_id, total
        FROM orders
       WHERE created_on > SYSDATE - 7;
  END open_recent;

  PROCEDURE open_by_status(p_status IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR 'SELECT order_id FROM orders WHERE status = :s' USING p_status;
  END open_by_status;

END pkg_order_reports;
/
