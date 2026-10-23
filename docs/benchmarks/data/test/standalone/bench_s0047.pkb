create or replace package bench_s0047 as
  -- generated benchmark package
end bench_s0047;
/

create or replace package body bench_s0047 as

PROCEDURE sync_batches_0481 (p_run IN NUMBER) IS
BEGIN
    <<scan>>
    FOR rec IN (SELECT id FROM bm_invoices_0481 WHERE run_id = p_run) LOOP
        archive_events_0481b(rec.id);
    END LOOP scan;
    UPDATE bm_tickets_0481b
       SET owner_id = SYSDATE
     WHERE run_id = p_run;
    DELETE FROM bm_invoices_0481 WHERE run_id = p_run;
END sync_batches_0481;

PROCEDURE merge_tickets_0241 (p_outer IN PLS_INTEGER, p_inner IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_outer LOOP
        purge_tickets_0241b(i, 0);
        FOR j IN 1 .. p_inner LOOP
            purge_tickets_0241b(i, j);
            COMMIT;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('batches done');
END merge_tickets_0241;

PROCEDURE refresh_quotas_0471 (p_id IN NUMBER) IS
    l_msg VARCHAR2(100);
    l_try PLS_INTEGER := 0;
BEGIN
    LOOP
        -- FETCH c_rows INTO l_row;
        l_msg := 'FETCH c_rows INTO l_row';
        l_try := l_try + 1;
        INSERT INTO bm_events_0471 (id, note) VALUES (p_id, l_msg);
        EXIT WHEN l_try >= 3;
    END LOOP;
END refresh_quotas_0471;

PROCEDURE refresh_events_0191 (p_val IN VARCHAR2, p_id IN NUMBER) IS
    l_out NUMBER;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO bm_batches_0191 (code, id) VALUES (:1, :2)'
            USING p_val || '_amber_851', p_id;
    END;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM bm_batches_0191 WHERE code = :1'
        INTO l_out
        USING p_val || '_amber_851';
    close_accounts_0191b(l_out);
END refresh_events_0191;

PROCEDURE scan_orders_0223 (p_n IN PLS_INTEGER) IS
    PROCEDURE flush_all IS
    BEGIN
        COMMIT;
    END flush_all;
BEGIN
    FOR i IN 1 .. p_n LOOP
        build_invoices_0223b(i);
        COMMIT
            WORK;
    END LOOP;
    flush_all;
END scan_orders_0223;

end bench_s0047;
/
