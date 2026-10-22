-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_invoice_stats AS

  PROCEDURE summarize(p_customer_id IN NUMBER) IS
    v_total NUMBER;
    v_first DATE;
    v_last  DATE;
    v_sum   NUMBER;
    v_now   DATE;
    v_id    NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_total FROM invoice WHERE customer_id = p_customer_id;

    SELECT MIN(issued_on), MAX(issued_on)
      INTO v_first, v_last
      FROM invoice
     WHERE customer_id = p_customer_id;

    SELECT SUM(amount) INTO v_sum FROM payment WHERE customer_id = p_customer_id;

    SELECT SYSDATE INTO v_now FROM dual;

    SELECT seq_invoice.NEXTVAL
      INTO v_id
      FROM dual;

    pkg_invoice_store.save_summary(p_customer_id, v_total, v_sum, v_first, v_last, v_now, v_id);
  END summarize;

  FUNCTION average_amount(p_customer_id IN NUMBER) RETURN NUMBER IS
    v_avg NUMBER;
  BEGIN
    SELECT AVG(amount) INTO v_avg FROM invoice WHERE customer_id = p_customer_id;
    RETURN v_avg;
  END average_amount;

END pkg_invoice_stats;
/
