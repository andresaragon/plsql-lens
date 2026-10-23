create or replace package bench_s0003 as
  -- generated benchmark package
end bench_s0003;
/

create or replace package body bench_s0003 as

PROCEDURE load_payments_0499 (p_run IN NUMBER) IS
BEGIN
    <<scan>>
    FOR rec IN (SELECT id FROM bm_batches_0499 WHERE run_id = p_run) LOOP
        sync_claims_0499b(rec.id);
    END LOOP scan;
    UPDATE bm_rates_0499b
       SET owner_id = SYSDATE
     WHERE run_id = p_run;
    DELETE FROM bm_batches_0499 WHERE run_id = p_run;
END load_payments_0499;

PROCEDURE check_shipments_0366 (p_dept IN NUMBER, p_cnt OUT NUMBER, p_hi OUT NUMBER) IS
    l_now DATE;
BEGIN
    SELECT COUNT(*), -- how many
           MAX(region) -- highest
      INTO p_cnt, p_hi
      FROM bm_orders_0366
     WHERE dept_id = p_dept;
    SELECT SYSDATE
      INTO l_now
      FROM
           DUAL;
    scan_shipments_0366b(l_now);
END check_shipments_0366;

FUNCTION close_events_0099 (p_code IN VARCHAR2) RETURN NUMBER IS
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
END close_events_0099;

PROCEDURE calc_quotas_0699 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    l_fee := p_qty * 55732;
    l_fee := l_fee + 58620;
    IF l_fee > 55732 THEN
        p_msg := 'juniper_186';
    ELSIF l_fee < 58620 THEN
        p_msg := 'ok_675231';
    ELSE
        p_msg := 'juniper_186';
    END IF;
END calc_quotas_0699;

FUNCTION audit_orders_0633 (p_base IN NUMBER) RETURN NUMBER IS
    l_a NUMBER;
    l_b NUMBER;
    l_c NUMBER;
BEGIN
    l_a := p_base * 24990;
    l_b := l_a + 24990;
    l_c := l_b / 24990;
    RETURN l_c;
END audit_orders_0633;

end bench_s0003;
/
