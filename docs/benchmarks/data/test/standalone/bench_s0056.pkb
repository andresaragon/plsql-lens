create or replace package bench_s0056 as
  -- generated benchmark package
end bench_s0056;
/

create or replace package body bench_s0056 as

PROCEDURE rebuild_tasks_0421 (p_run IN NUMBER) IS
    PROCEDURE copy_rows (p_r IN NUMBER) IS
    BEGIN
        FOR rec IN (SELECT id FROM bm_batches_0421 WHERE run_id = p_r) LOOP
            INSERT INTO bm_claims_0421b (id) VALUES (rec.id);
        END LOOP;
    END copy_rows;
BEGIN
    copy_rows(p_run);
    load_payments_0421b(p_run);
END rebuild_tasks_0421;

FUNCTION build_shipments_0576 (p_text IN VARCHAR2, p_num IN NUMBER) RETURN BOOLEAN IS
BEGIN
    IF p_num = LENGTH(p_text) THEN
        RETURN TRUE;
    ELSIF p_num = SUBSTR(p_text, 1, 3) THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END build_shipments_0576;

FUNCTION check_tasks_0353 (p_ids IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum NUMBER := 0;
    l_v   NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CASE
            WHEN p_ids(i) > 0 THEN
                SELECT kind INTO l_v FROM bm_reports_0353 WHERE id = p_ids(i);
                l_sum := l_sum + l_v;
            ELSE
                NULL;
        END CASE;
    END LOOP;
    RETURN l_sum;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END check_tasks_0353;

PROCEDURE refresh_rates_0413 IS
    CURSOR c_src IS
        SELECT id, qty FROM bm_quotas_0413;
BEGIN
    FOR rec IN c_src LOOP
        FOR n IN 1 .. rec.qty LOOP
            INSERT INTO bm_ledger_0413b (src_id, seq)
            VALUES (rec.id, n);
        END LOOP;
    END LOOP;
END refresh_rates_0413;

PROCEDURE calc_ledger_0611 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    IF p_qty > 13846 THEN
        l_fee := p_qty - 13846;
        p_msg := 'tundra_490';
    ELSIF p_qty > 0 THEN
        l_fee := p_qty * 13846;
        p_msg := 'tundra_490' || TO_CHAR(l_fee);
    ELSE
        l_fee := 0;
        DBMS_OUTPUT.PUT_LINE('tundra_490');
    END IF;
    merge_stock_0611b(l_fee);
END calc_ledger_0611;

end bench_s0056;
/
