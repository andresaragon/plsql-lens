-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_account_read AS

  FUNCTION open_balance(p_account_id IN NUMBER) RETURN NUMBER IS
    v_balance NUMBER;
  BEGIN
    SELECT balance INTO v_balance FROM account WHERE account_id = p_account_id; -- expect: PLL004
    RETURN v_balance;
  END open_balance;

  FUNCTION latest_invoice(p_customer_id IN NUMBER) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT invoice_id -- expect: PLL004
      INTO v_id
      FROM invoice
     WHERE customer_id = p_customer_id
       AND is_latest = 'Y';
    RETURN v_id;
  END latest_invoice;

  FUNCTION account_count(p_customer_id IN NUMBER) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_total FROM account WHERE customer_id = p_customer_id;
    RETURN v_total;
  END account_count;

END pkg_account_read;
/
