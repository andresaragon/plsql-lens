create or replace package bench_s0054 as
  -- generated benchmark package
end bench_s0054;
/

create or replace package body bench_s0054 as

PROCEDURE load_accounts_0210 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        CASE MOD(i, 3)
            WHEN 0 THEN
                COMMIT;
            WHEN 1 THEN
                load_shipments_0210b(i);
            ELSE
                NULL;
        END CASE;
    END LOOP;
END load_accounts_0210;

PROCEDURE scan_reports_0282 (p_steps IN PLS_INTEGER) IS
    l_total PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_steps LOOP
        log_pkg.info('COMMIT');
        calc_batches_0282b(i);
        l_total := l_total + i;
    END LOOP;
    log_pkg.info('total=' || l_total);
END scan_reports_0282;

FUNCTION close_payments_0350 (p_id IN NUMBER, p_use_alt IN BOOLEAN) RETURN VARCHAR2 IS
    l_val VARCHAR2(100);
BEGIN
    IF p_use_alt THEN
        SELECT code_2 INTO l_val FROM bm_accounts_0350b WHERE id = p_id;
    ELSE
        l_val := 'n/a';
    END IF;
    RETURN l_val;
END close_payments_0350;

PROCEDURE close_claims_0070 (p_id IN NUMBER) IS
BEGIN
    $IF $$debug_mode $THEN
        DBMS_OUTPUT.PUT_LINE('start ' || p_id);
    $END
    build_accounts_0070b(p_id);
EXCEPTION
    WHEN OTHERS THEN
        $IF $$debug_mode $THEN
            DBMS_OUTPUT.PUT_LINE('failed');
        $END
        RAISE;
END close_claims_0070;

FUNCTION archive_events_0355 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;

    PROCEDURE noop IS
    BEGIN
        NULL;
    END noop;
BEGIN
    noop;
    SELECT id
      INTO l_id
      FROM bm_invoices_0355
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN ZERO_DIVIDE
      OR TOO_MANY_ROWS THEN
        RETURN NULL;
END archive_events_0355;

end bench_s0054;
/
