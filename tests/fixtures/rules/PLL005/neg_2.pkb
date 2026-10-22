-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_billing_adjust AS

  TYPE t_id_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

  PROCEDURE apply_discount(p_ids IN t_id_tab, p_pct IN NUMBER) IS
  BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
      UPDATE invoices SET amount = amount * (1 - p_pct / 100) WHERE invoice_id = p_ids(i);
    END LOOP;
  END apply_discount;

  PROCEDURE seed_periods(p_year IN NUMBER) IS
  BEGIN
    FOR m IN 1 .. 12 LOOP
      INSERT INTO billing_periods (period_year, period_month) VALUES (p_year, m);
    END LOOP;
  END seed_periods;

  PROCEDURE reset_counters(p_n IN NUMBER) IS
  BEGIN
    FOR k IN REVERSE 1 .. p_n LOOP
      DELETE FROM billing_counters WHERE counter_id = k;
    END LOOP;
  END reset_counters;

END pkg_billing_adjust;
/
