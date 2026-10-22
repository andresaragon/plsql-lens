-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_invoice_calc AS

  FUNCTION net_amount(p_invoice_id IN NUMBER) RETURN NUMBER IS
    v_gross NUMBER;
    v_tax   NUMBER;
  BEGIN
    v_gross := pkg_invoice_store.gross_of(p_invoice_id);
    v_tax   := pkg_invoice_store.tax_of(p_invoice_id);
    RETURN v_gross - v_tax;
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      RETURN -1;
  END net_amount;

  FUNCTION is_overdue(p_invoice_id IN NUMBER) RETURN BOOLEAN IS
    v_due DATE;
  BEGIN
    v_due := pkg_invoice_store.due_date_of(p_invoice_id);
    RETURN v_due < SYSDATE;
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      RETURN FALSE;
  END is_overdue;

  FUNCTION has_lines(p_invoice_id IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    RETURN pkg_invoice_store.line_total(p_invoice_id) > 0;
  END has_lines;

END pkg_invoice_calc;
/
