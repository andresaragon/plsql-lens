-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_billing_totals AS

  PROCEDURE refresh_paid_total IS
    l_sum NUMBER := 0;
  BEGIN
    FOR r IN (SELECT amount FROM invoices WHERE status = 'PAID') LOOP
      l_sum := l_sum + r.amount;
    END LOOP;
    UPDATE billing_summary SET paid_total = l_sum WHERE summary_id = 7;
  END refresh_paid_total;

  PROCEDURE stamp_overdue IS
    CURSOR c_due IS SELECT invoice_id FROM invoices WHERE due_on < SYSDATE;
    l_id    NUMBER;
    l_count NUMBER := 0;
  BEGIN
    OPEN c_due;
    LOOP
      FETCH c_due INTO l_id;
      EXIT WHEN c_due%NOTFOUND;
      l_count := l_count + 1;
    END LOOP;
    CLOSE c_due;
    INSERT INTO billing_audit (note, cnt) VALUES ('overdue scan', l_count);
  END stamp_overdue;

END pkg_billing_totals;
/
