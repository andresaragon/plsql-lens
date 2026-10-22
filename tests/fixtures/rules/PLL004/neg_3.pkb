-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_batch_read AS

  TYPE t_ids    IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  TYPE t_totals IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

  PROCEDURE load_open_orders(p_customer_id IN NUMBER) IS
    v_ids    t_ids;
    v_totals t_totals;
  BEGIN
    SELECT order_id, total
      BULK COLLECT INTO v_ids, v_totals
      FROM orders
     WHERE customer_id = p_customer_id
       AND status = 'OPEN';
    FOR i IN 1 .. v_ids.COUNT LOOP
      pkg_order_store.queue_order(v_ids(i), v_totals(i));
    END LOOP;
  END load_open_orders;

  FUNCTION order_total(p_order_id IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    SELECT total INTO v_total FROM orders WHERE order_id = p_order_id;
    RETURN v_total;
  EXCEPTION
    WHEN TOO_MANY_ROWS THEN
      RETURN NULL;
  END order_total;

  PROCEDURE load_ids(p_status IN VARCHAR2, p_ids OUT t_ids) IS
  BEGIN
    SELECT order_id BULK COLLECT INTO p_ids FROM orders WHERE status = p_status;
  END load_ids;

END pkg_order_batch_read;
/
