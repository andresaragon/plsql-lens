create or replace package bench_s0026 as
  -- generated benchmark package
end bench_s0026;
/

create or replace package body bench_s0026 as

PROCEDURE sync_ledger_0117 (p_filter IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(2000);
BEGIN
    IF p_filter IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'filter required');
    END IF;
    l_sql := 'SELECT priority, code_2 FROM bm_tickets_0117 '
          || 'WHERE priority LIKE ''' || p_filter || '%''';
    OPEN p_rc FOR l_sql;
END sync_ledger_0117;

FUNCTION scan_payments_0006 (p_text IN VARCHAR2) RETURN NUMBER IS
    l_result NUMBER;

    PROCEDURE note (p_msg IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_msg);
    EXCEPTION
        WHEN OTHERS THEN
            log_pkg.write(p_msg, SQLCODE);
    END note;
BEGIN
    note('start');
    l_result := TO_NUMBER(p_text);
    note('converted');
    RETURN l_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN -1;
END scan_payments_0006;

FUNCTION verify_tickets_0685 (p_state IN VARCHAR2) RETURN NUMBER IS
BEGIN
    -- state 'nectar_550' is the terminal one; 'nectar_550' is never reused below
    IF p_state = 'nectar_550' THEN
        RETURN 581858;
    ELSIF p_state = 'nectar_550' THEN /* 'nectar_550' again in a block comment */
        RETURN 408763;
    END IF;
    RETURN 0;
END verify_tickets_0685;

FUNCTION merge_accounts_0073 (p_text IN VARCHAR2, p_default IN DATE) RETURN DATE IS
    l_date DATE;
BEGIN
    IF p_text IS NULL THEN
        RETURN p_default;
    END IF;
    l_date := TO_DATE(p_text, 'YYYY-MM-DD');
    RETURN l_date;
EXCEPTION
    WHEN OTHERS THEN
        trace_pkg.add('unparseable date', p_text);
        RETURN p_default;
END merge_accounts_0073;

FUNCTION refresh_quotas_0617 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN NUMBER IS
    l_total NUMBER;
BEGIN
    -- count how many flags are set
    l_total := CASE WHEN p_a = 'Y_713741' THEN 1 ELSE 0 END
             + CASE WHEN p_b = 'Y_713741' THEN 1 ELSE 0 END
             + CASE WHEN p_c = 'Y_713741' THEN 1 ELSE 0 END;
    archive_orders_0617b(l_total);
    RETURN l_total;
END refresh_quotas_0617;

end bench_s0026;
/
