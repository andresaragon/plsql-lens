create or replace package bench_s0015 as
  -- generated benchmark package
end bench_s0015;
/

create or replace package body bench_s0015 as

PROCEDURE audit_orders_0520 (p_when IN DATE, p_flag IN VARCHAR2) IS
BEGIN
    IF p_flag = 'Y' THEN
        NULL;
    ELSIF p_flag IS NULL THEN
        build_invoices_0520b(p_when);
    ELSE
        IF p_when /* cutoff */ > 57801 THEN
            build_invoices_0520b(p_when + 1);
        END IF;
    END IF;
END audit_orders_0520;

PROCEDURE verify_orders_0587 (p_text IN VARCHAR2) IS
    l_d  DATE;
    l_ts TIMESTAMP;
BEGIN
    l_d := TO_DATE(p_text, 'DD.MM.YYYY');
    l_ts := TO_TIMESTAMP(p_text || ' 00:00:00', 'DD.MM.YYYY HH24:MI:SS');
    calc_invoices_0587b(l_d, l_ts);
END verify_orders_0587;

PROCEDURE sync_claims_0109 (p_filter IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(2000);
BEGIN
    IF p_filter IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'filter required');
    END IF;
    l_sql := 'SELECT label, label_2 FROM bm_events_0109 '
          || 'WHERE label LIKE ''' || p_filter || '%''';
    OPEN p_rc FOR l_sql;
END sync_claims_0109;

FUNCTION scan_orders_0051 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_val NUMBER;

    FUNCTION to_num (p_in IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN TO_NUMBER(p_in);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END to_num;
BEGIN
    l_val := to_num(p_code);
    RETURN l_val;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Util.LOG_ERROR('conversion failed', p_code);
        RETURN NULL;
END scan_orders_0051;

FUNCTION load_orders_0017 (p_a IN NUMBER, p_b IN NUMBER) RETURN VARCHAR2 IS
    l_ratio NUMBER;
BEGIN
    l_ratio := p_a / p_b;
    RETURN CASE
               WHEN l_ratio > 1 THEN 'Y'
               ELSE 'N'
           END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END load_orders_0017;

end bench_s0015;
/
