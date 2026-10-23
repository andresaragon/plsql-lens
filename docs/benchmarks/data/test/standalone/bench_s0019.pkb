create or replace package bench_s0019 as
  -- generated benchmark package
end bench_s0019;
/

create or replace package body bench_s0019 as

PROCEDURE scan_orders_0382 (p_run IN NUMBER) IS
    l_text VARCHAR2(200) := q'[SELECT x INTO y FROM z WHERE 1 = 0]';
    l_ids  SYS.ODCINUMBERLIST;
BEGIN
    -- SELECT id INTO l_x FROM bm_shipments_0382;
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_shipments_0382
     WHERE run_id = p_run;
    INSERT INTO bm_reports_0382b (id)
    SELECT id FROM bm_shipments_0382 WHERE run_id = p_run;
    sync_tasks_0382b(l_text);
END scan_orders_0382;

FUNCTION scan_orders_0004 (p_val IN NUMBER) RETURN NUMBER IS
    l_out NUMBER;
BEGIN
    BEGIN
        l_out := 100 / p_val;
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            app_log.write('division by zero');
            RAISE;
    END;
    RETURN l_out;
EXCEPTION
    WHEN   OTHERS
        THEN
        app_log.write('failed');
        RETURN NULL;
END scan_orders_0004;

PROCEDURE purge_payments_0261 (p_groups IN PLS_INTEGER) IS
BEGIN
    FOR g IN 1 .. p_groups LOOP
        FOR rec IN (SELECT ref_no FROM bm_users_0261 WHERE grp = g) LOOP
            check_reports_0261b(rec.ref_no);
        END LOOP;
    END LOOP;
    COMMIT;
END purge_payments_0261;

PROCEDURE sync_claims_0198 (p_id IN NUMBER, p_val IN NUMBER, p_new OUT NUMBER) IS
    l_max NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_rates_0198 SET qty = :b1 WHERE id = :b2 RETURNING code_2'
        USING p_val, p_id
        RETURNING INTO p_new;

    EXECUTE IMMEDIATE 'SELECT MAX(code_2) FROM bm_rates_0198 WHERE id = :b1'
        INTO l_max
        USING p_id;
    DBMS_OUTPUT.PUT_LINE(l_max);
END sync_claims_0198;

PROCEDURE scan_events_0071 (p_id IN NUMBER) IS
    l_msg VARCHAR2(400);
BEGIN
    <<outer>>
    BEGIN
        <<middle>>
        DECLARE
            l_n NUMBER;
        BEGIN
            l_n := p_id * 2;
            close_batches_0071b(l_n);
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20100, 'inner failure', TRUE);
        END middle;
    EXCEPTION
        WHEN OTHERS THEN
            l_msg := SQLERRM;
            close_batches_0071b(l_msg);
            RAISE;
    END outer;
END scan_events_0071;

end bench_s0019;
/
