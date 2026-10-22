-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_invoice_priority AS

  PROCEDURE escalate_large_invoices IS
    CURSOR c_inv IS
      SELECT invoice_id, total_amount FROM invoices WHERE paid_flag = 'N';
    l_id    NUMBER;
    l_total NUMBER;
  BEGIN
    OPEN c_inv;
    LOOP
      FETCH c_inv INTO l_id, l_total;
      EXIT WHEN c_inv%NOTFOUND;
      IF l_total > 5000 THEN
        UPDATE invoices SET priority = 'HIGH' WHERE invoice_id = l_id; -- expect: PLL005
      END IF;
    END LOOP;
    CLOSE c_inv;
  END escalate_large_invoices;

  PROCEDURE drop_empty_invoices IS
    CURSOR c_empty IS
      SELECT invoice_id FROM invoices WHERE total_amount IS NULL;
    l_id NUMBER;
  BEGIN
    OPEN c_empty;
    LOOP
      FETCH c_empty INTO l_id;
      EXIT WHEN c_empty%NOTFOUND;
      DELETE FROM invoices WHERE invoice_id = l_id; -- expect: PLL005
    END LOOP;
    CLOSE c_empty;
  END drop_empty_invoices;

END pkg_invoice_priority;
/
