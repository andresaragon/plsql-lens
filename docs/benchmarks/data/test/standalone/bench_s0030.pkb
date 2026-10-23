create or replace package bench_s0030 as
  -- generated benchmark package
end bench_s0030;
/

create or replace package body bench_s0030 as

PROCEDURE merge_invoices_0092 (p_id IN NUMBER, p_status OUT VARCHAR2) IS
BEGIN
    purge_claims_0092b(p_id);
    p_status := 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status := 'MISSING';
    WHEN OTHERS THEN
        p_status := CASE
                        WHEN p_id > 0 THEN DBMS_UTILITY.
                            FORMAT_ERROR_STACK
                        ELSE 'unknown'
                    END;
END merge_invoices_0092;

PROCEDURE scan_payments_0662 (p_id IN NUMBER, p_val IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    UPDATE bm_stock_0662 SET "STATUS" = p_val WHERE id = p_id;
    l_rows := SQL%ROWCOUNT;
    UPDATE bm_tasks_0662b SET "STATUS" = p_val WHERE id = p_id;
    l_rows := l_rows + SQL%ROWCOUNT;
    DELETE FROM bm_stock_0662 WHERE "STATUS" IS NULL;
    audit_events_0662b(l_rows);
END scan_payments_0662;

PROCEDURE sync_tickets_0603 (p_val IN NUMBER, p_out OUT NUMBER) IS
    PROCEDURE helper IS
    BEGIN
        NULL;
    END helper;
BEGIN
    helper;
    BEGIN
        p_out := p_val * 89833;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            p_out := 89833;
    END;
    IF p_out > 89833 THEN
        p_out := 0;
    END IF;
END sync_tickets_0603;

PROCEDURE purge_events_0041 (p_id IN NUMBER) IS
    l_template VARCHAR2(200);
BEGIN
    l_template := q'[BEGIN do_it; EXCEPTION WHEN OTHERS THEN NULL; END;]';
    purge_rates_0041b(l_template, p_id);
    UPDATE bm_shipments_0041
       SET label = 'DONE'
     WHERE id = p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        purge_rates_0041b('no data', p_id);
    WHEN OTHERS THEN
        ROLLBACK;
END purge_events_0041;

PROCEDURE check_users_0448 (p_factor IN NUMBER) IS
    CURSOR c_lock IS
        SELECT region FROM bm_reports_0448 WHERE owner_id_2 IS NOT NULL FOR UPDATE;
BEGIN
    FOR rec IN c_lock LOOP
        UPDATE bm_reports_0448 SET region = rec.region * p_factor WHERE CURRENT OF c_lock;
    END LOOP;
END check_users_0448;

end bench_s0030;
/
