-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_billing_limits AS

  c_max_days   CONSTANT NUMBER := 365;
  c_grace_days CONSTANT NUMBER := 30;
  c_pending    CONSTANT VARCHAR2(10) := 'PENDING';

  FUNCTION is_expired(p_days IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    IF p_days > c_max_days THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_expired;

  FUNCTION grace_left(p_days IN NUMBER) RETURN NUMBER IS
  BEGIN
    IF p_days > c_max_days THEN
      RETURN 0;
    END IF;
    RETURN LEAST(c_grace_days, c_max_days - p_days);
  END grace_left;

  PROCEDURE mark_pending(p_invoice_id IN NUMBER, p_status OUT VARCHAR2) IS
  BEGIN
    p_status := c_pending;
    UPDATE invoices SET status = c_pending WHERE invoice_id = p_invoice_id;
  END mark_pending;

  FUNCTION is_pending(p_status IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF p_status = c_pending THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_pending;

END pkg_billing_limits;
/
