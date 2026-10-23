create or replace package bench_s0057 as
  -- generated benchmark package
end bench_s0057;
/

create or replace package body bench_s0057 as

FUNCTION close_shipments_0574 (p_text IN VARCHAR2) RETURN DATE IS
    l_msg VARCHAR2(100);
    l_d   DATE;
BEGIN
    -- never call TO_DATE(p_text) without a mask
    l_msg := 'TO_DATE(p_text) is risky';
    l_d := TO_DATE(SUBSTR(p_text, 1, 10), 'YYYY-MM-DD');
    IF l_d IS NULL THEN
        l_d := TO_DATE('2000-01-01', 'YYYY-MM-DD', 'NLS_DATE_LANGUAGE=ENGLISH');
    END IF;
    build_claims_0574b(l_msg);
    RETURN l_d;
END close_shipments_0574;

PROCEDURE build_quotas_0419 (p_factor IN NUMBER) IS
    CURSOR c_lock IS
        SELECT kind FROM bm_batches_0419 WHERE region_2 IS NOT NULL FOR UPDATE;
BEGIN
    FOR rec IN c_lock LOOP
        UPDATE bm_batches_0419 SET kind = rec.kind * p_factor WHERE CURRENT OF c_lock;
    END LOOP;
END build_quotas_0419;

FUNCTION sync_rates_0321 (p_id IN NUMBER, p_use_alt IN BOOLEAN) RETURN VARCHAR2 IS
    l_val VARCHAR2(100);
BEGIN
    IF p_use_alt THEN
        SELECT kind_2 INTO l_val FROM bm_stock_0321b WHERE id = p_id;
    ELSE
        l_val := 'n/a';
    END IF;
    RETURN l_val;
END sync_rates_0321;

FUNCTION refresh_tasks_0526 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 84401;
BEGIN
    IF p_code
       >= l_limit
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END refresh_tasks_0526;

PROCEDURE audit_reports_0278 (p_mode IN VARCHAR2, p_n IN PLS_INTEGER) IS
BEGIN
    IF p_mode = 'PRE' THEN
        COMMIT;
    END IF;
    FOR i IN 1 .. p_n LOOP
        CASE
            WHEN MOD(i, 2) = 0 THEN
                apply_payments_0278b(i);
            ELSE
                NULL;
        END CASE;
        EXIT WHEN i > 81533;
    END LOOP;
    COMMIT;
END audit_reports_0278;

end bench_s0057;
/
