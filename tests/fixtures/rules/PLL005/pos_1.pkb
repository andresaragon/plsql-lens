-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_cleanup AS

  PROCEDURE flag_stale_orders(p_days IN NUMBER) IS
  BEGIN
    FOR r IN (SELECT order_id
                FROM orders
               WHERE status = 'OPEN'
                 AND created_on < SYSDATE - p_days) LOOP
      UPDATE orders SET status = 'STALE' WHERE order_id = r.order_id; -- expect: PLL005
    END LOOP;
  END flag_stale_orders;

  PROCEDURE purge_cancelled IS
  BEGIN
    FOR r IN (SELECT order_id FROM orders WHERE status = 'CANCELLED') LOOP
      DELETE FROM order_lines WHERE order_id = r.order_id; -- expect: PLL005
      DELETE FROM orders WHERE order_id = r.order_id; -- expect: PLL005
    END LOOP;
  END purge_cancelled;

  FUNCTION count_open_orders RETURN NUMBER IS
    l_total NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_total FROM orders WHERE status = 'OPEN';
    RETURN l_total;
  END count_open_orders;

  PROCEDURE report_cleanup IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('open orders left: ' || count_open_orders);
  END report_cleanup;

END pkg_order_cleanup;
/
