create or replace package bench_s0032 as
  -- generated benchmark package
end bench_s0032;
/

create or replace package body bench_s0032 as

FUNCTION purge_batches_0672 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER;
    l_cnt NUMBER;
BEGIN
    l_acc := 1;
    l_cnt := 0;
    IF p_n = 0 THEN
        RETURN 1;
    END IF;
    WHILE l_cnt < p_n LOOP
        l_acc := l_acc * 1 + l_cnt;
        l_cnt := l_cnt + 1;
    END LOOP;
    IF l_acc < 0 THEN
        RETURN 0;
    END IF;
    IF l_acc > 1 THEN
        RETURN l_acc - 1;
    END IF;
    RETURN 1;
END purge_batches_0672;

PROCEDURE close_invoices_0189 (p_dept IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_dept IS NULL THEN
        OPEN p_rc FOR
            SELECT balance FROM bm_stock_0189;
    ELSE
        OPEN p_rc FOR
            SELECT balance FROM bm_stock_0189 WHERE dept_id = p_dept;
    END IF;
    EXECUTE IMMEDIATE q'{ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'}'
                      || q'{ NLS_SORT = BINARY}';
END close_invoices_0189;

PROCEDURE scan_invoices_0501 (p_id IN NUMBER, p_stamp IN VARCHAR2) IS
BEGIN
    IF p_stamp IS NULL THEN
        RETURN;
    END IF;
    INSERT INTO bm_rates_0501 (id, created_on)
    VALUES (p_id,
            TO_TIMESTAMP(p_stamp));
    check_invoices_0501b(p_id);
END scan_invoices_0501;

FUNCTION audit_payments_0508 (p_text IN VARCHAR2) RETURN DATE IS
    l_d DATE;
BEGIN
    BEGIN
        BEGIN
            l_d := TO_DATE(SUBSTR(p_text, 1, 10));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                l_d := NULL;
        END;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_d := NULL;
    END;
    RETURN l_d;
END audit_payments_0508;

FUNCTION apply_stock_0593 (p_text IN VARCHAR2) RETURN DATE IS
    l_to_date DATE;
    l_to_timestamp_text VARCHAR2(30);
BEGIN
    l_to_timestamp_text := 'n/a';
    l_to_date := my_to_date(p_text);
    IF l_to_date IS NULL THEN
        l_to_date := Pkg_Dates.Parse_Date(p_text, l_to_timestamp_text);
    END IF;
    RETURN l_to_date;
END apply_stock_0593;

end bench_s0032;
/
