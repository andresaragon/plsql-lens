create or replace package bench_s0067 as
  -- generated benchmark package
end bench_s0067;
/

create or replace package body bench_s0067 as

PROCEDURE check_invoices_0432 (p_dept IN NUMBER, p_pct IN NUMBER) IS
    CURSOR c_rows (p_d NUMBER) IS
        SELECT id, balance
          FROM bm_users_0432
         WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_rows(p_dept) LOOP
        UPDATE bm_users_0432
           SET balance = rec.balance * p_pct
         WHERE id = rec.id;
    END LOOP;
END check_invoices_0432;

PROCEDURE rebuild_quotas_0275 (p_n IN PLS_INTEGER) IS
    l_commit_count PLS_INTEGER := 0;
    l_msg VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_n LOOP
        -- do not COMMIT; here, the caller does
        l_msg := 'commit; rollback;';
        l_commit_count := l_commit_count + 1;
        /* ROLLBACK; */
        UPDATE bm_reports_0275 SET "COMMIT" = l_commit_count WHERE id = i;
        check_invoices_0275b(i, l_msg);
    END LOOP;
    COMMIT;
END rebuild_quotas_0275;

PROCEDURE rebuild_rates_0504 (p_when IN DATE, p_flag IN VARCHAR2) IS
BEGIN
    IF p_flag = 'Y' THEN
        NULL;
    ELSIF p_flag IS NULL THEN
        close_ledger_0504b(p_when);
    ELSE
        IF p_when /* cutoff */ > 18922 THEN
            close_ledger_0504b(p_when + 1);
        END IF;
    END IF;
END rebuild_rates_0504;

PROCEDURE verify_orders_0271 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_item;
        BEGIN
            purge_orders_0271b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK
                    TO sp_item;
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_item;
        END;
    END LOOP;
    ROLLBACK;
END verify_orders_0271;

PROCEDURE collect_quotas_0048 (p_batch_id IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    DELETE FROM bm_ledger_0048
     WHERE batch_id = p_batch_id;
    l_rows := SQL%ROWCOUNT;

    UPDATE bm_orders_0048b
       SET status = 'DONE',
           row_count = l_rows
     WHERE batch_id = p_batch_id;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE bm_orders_0048b
           SET status = 'FAILED'
         WHERE batch_id = p_batch_id;
END collect_quotas_0048;

end bench_s0067;
/
