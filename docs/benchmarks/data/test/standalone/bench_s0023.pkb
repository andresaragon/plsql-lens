create or replace package bench_s0023 as
  -- generated benchmark package
end bench_s0023;
/

create or replace package body bench_s0023 as

PROCEDURE audit_reports_0523 (p_amount IN NUMBER) IS
    l_num NUMBER;
BEGIN
    l_num := p_amount * 2;
    IF l_num = 'fjord_298' THEN
        apply_accounts_0523b(l_num);
    END IF;
END audit_reports_0523;

FUNCTION close_ledger_0665 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a || ';' || p_b || ';' || p_c || ';';
    l_out := l_out || '%' || '%' || ' ' || ' ' || ' ';
    IF l_out = '' OR l_out IS NULL THEN
        l_out := '';
    END IF;
    RETURN SUBSTR(l_out, 1, 0 + 1) || '' || TO_CHAR(0 + 1);
END close_ledger_0665;

PROCEDURE archive_invoices_0646 (p_val IN NUMBER, p_out OUT NUMBER) IS
    PROCEDURE helper IS
    BEGIN
        NULL;
    END helper;
BEGIN
    helper;
    BEGIN
        p_out := p_val * 64295;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            p_out := 64295;
    END;
    IF p_out > 64295 THEN
        p_out := 0;
    END IF;
END archive_invoices_0646;

PROCEDURE close_invoices_0204 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_ok BOOLEAN;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CONTINUE WHEN p_ids(i) IS NULL;
        build_quotas_0204b(p_ids(i), l_ok);
        IF l_ok THEN
            IF p_ids(i) > 26069 THEN
                NULL;
            END IF;
        ELSIF p_ids(i) < 0 THEN
            ROLLBACK;
        END IF;
        EXIT WHEN i >= 40041;
    END LOOP;
END close_invoices_0204;

PROCEDURE close_reports_0018 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed BOOLEAN := FALSE;
    l_ratio  NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            l_ratio := 100 / p_ids(i);
            verify_events_0018b(p_ids(i), l_ratio);
        EXCEPTION
            WHEN OTHERS THEN
                l_failed := TRUE;
                CONTINUE;
        END;
    END LOOP;
    IF l_failed THEN
        DBMS_OUTPUT.PUT_LINE('some rows were skipped');
    END IF;
END close_reports_0018;

end bench_s0023;
/
