-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_customer_search AS

  FUNCTION count_by_name(p_name IN VARCHAR2) RETURN NUMBER IS
    v_sql   VARCHAR2(400);
    v_count NUMBER;
  BEGIN
    v_sql := 'SELECT COUNT(*) FROM customer WHERE last_name = ''' || p_name || '''';
    EXECUTE IMMEDIATE v_sql INTO v_count; -- expect: PLL002
    RETURN v_count;
  END count_by_name;

  PROCEDURE set_invoice_status(p_invoice_id IN NUMBER, p_status IN VARCHAR2) IS
    v_stmt VARCHAR2(400);
  BEGIN
    v_stmt := 'UPDATE invoice SET status = ''' || p_status || ''' WHERE invoice_id = :1';
    EXECUTE IMMEDIATE v_stmt -- expect: PLL002
      USING p_invoice_id;
  END set_invoice_status;

  FUNCTION count_active RETURN NUMBER IS
    v_sql   VARCHAR2(200) := 'SELECT COUNT(*) FROM customer WHERE active_flag = ''Y''';
    v_count NUMBER;
  BEGIN
    EXECUTE IMMEDIATE v_sql INTO v_count;
    RETURN v_count;
  END count_active;

END pkg_customer_search;
/
