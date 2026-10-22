-- Written for this repo.
CREATE OR REPLACE PROCEDURE accrue_invoice_interest(
  p_invoice_id IN NUMBER,
  p_days_open  IN NUMBER,
  p_amount     IN NUMBER
) IS
  l_years    NUMBER;
  l_interest NUMBER;
  l_bucket   VARCHAR2(20);
BEGIN
  l_years := p_days_open / 365; -- expect: PLL007
  IF p_days_open > 365 THEN -- expect: PLL007
    l_bucket := 'OVERDUE';
  ELSE
    l_bucket := 'CURRENT';
  END IF;
  l_interest := p_amount * 0.05 * (p_days_open / 365); -- expect: PLL007
  IF l_years > 2 THEN
    l_interest := l_interest * 1.5;
  END IF;
  UPDATE invoices
     SET interest_due = l_interest,
         age_bucket   = l_bucket
   WHERE invoice_id = p_invoice_id;
  DBMS_OUTPUT.PUT_LINE('accrued interest for invoice ' || p_invoice_id);
END accrue_invoice_interest;
/
