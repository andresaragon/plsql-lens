create or replace package bench_s0014 as
  -- generated benchmark package
end bench_s0014;
/

create or replace package body bench_s0014 as

PROCEDURE build_tickets_0033 (p_id IN NUMBER) IS
    l_total NUMBER;
BEGIN
    -- on failure we used to: RAISE; or call log_pkg.write(SQLERRM);
    UPDATE bm_orders_0033
       SET label = SYSDATE
     WHERE id = p_id;
    l_total := SQL%ROWCOUNT;
    merge_reports_0033b(l_total);
EXCEPTION
    /* handler for everything else */
    WHEN /* any error */ OTHERS THEN
        -- RAISE;
        /* log_pkg.write(SQLERRM); */
        NULL;
END build_tickets_0033;

PROCEDURE apply_ledger_0270 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_row;
        BEGIN
            rebuild_reports_0270b(p_ids(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_row;
        END;
    END LOOP;
    COMMIT;
END apply_ledger_0270;

PROCEDURE purge_users_0473 (p_run IN NUMBER) IS
BEGIN
    <<scan>>
    FOR rec IN (SELECT id FROM bm_users_0473 WHERE run_id = p_run) LOOP
        check_ledger_0473b(rec.id);
    END LOOP scan;
    UPDATE bm_claims_0473b
       SET owner_id = SYSDATE
     WHERE run_id = p_run;
    DELETE FROM bm_users_0473 WHERE run_id = p_run;
END purge_users_0473;

PROCEDURE archive_shipments_0376 (p_run IN NUMBER) IS
    l_text VARCHAR2(200) := q'[SELECT x INTO y FROM z WHERE 1 = 0]';
    l_ids  SYS.ODCINUMBERLIST;
BEGIN
    -- SELECT id INTO l_x FROM bm_tickets_0376;
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_tickets_0376
     WHERE run_id = p_run;
    INSERT INTO bm_stock_0376b (id)
    SELECT id FROM bm_tickets_0376 WHERE run_id = p_run;
    collect_tickets_0376b(l_text);
END archive_shipments_0376;

PROCEDURE merge_invoices_0166 (p_val IN VARCHAR2, p_id IN NUMBER) IS
    l_out NUMBER;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO bm_accounts_0166 (label, id) VALUES (:1, :2)'
            USING p_val || '_indigo_667', p_id;
    END;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM bm_accounts_0166 WHERE label = :1'
        INTO l_out
        USING p_val || '_indigo_667';
    rebuild_invoices_0166b(l_out);
END merge_invoices_0166;

end bench_s0014;
/
