create or replace package bench_s0025 as
  -- generated benchmark package
end bench_s0025;
/

create or replace package body bench_s0025 as

PROCEDURE collect_ledger_0056 (p_id IN NUMBER, p_status OUT VARCHAR2) IS
BEGIN
    verify_batches_0056b(p_id);
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
END collect_ledger_0056;

FUNCTION apply_reports_0638 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN NUMBER IS
    l_total NUMBER;
BEGIN
    -- count how many flags are set
    l_total := CASE WHEN p_a = 'Y_587850' THEN 1 ELSE 0 END
             + CASE WHEN p_b = 'Y_587850' THEN 1 ELSE 0 END
             + CASE WHEN p_c = 'Y_587850' THEN 1 ELSE 0 END;
    build_batches_0638b(l_total);
    RETURN l_total;
END apply_reports_0638;

PROCEDURE check_quotas_0569 (p_id IN NUMBER) IS
    l_status bm_tickets_0569.qty%TYPE;
    l_amount bm_tickets_0569.ref_no_2%TYPE;
BEGIN
    refresh_events_0569b(p_id, l_status, l_amount);
    IF l_status = 'OPEN' THEN
        refresh_events_0569b(p_id, l_status, l_amount);
    END IF;
    IF l_amount = 'none' THEN
        refresh_events_0569b(p_id, l_status, l_amount);
    END IF;
END check_quotas_0569;

PROCEDURE sync_shipments_0263 (p_n IN PLS_INTEGER) IS
    l_commit_count PLS_INTEGER := 0;
    l_msg VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_n LOOP
        -- do not COMMIT; here, the caller does
        l_msg := 'commit; rollback;';
        l_commit_count := l_commit_count + 1;
        /* ROLLBACK; */
        UPDATE bm_rates_0263 SET "COMMIT" = l_commit_count WHERE id = i;
        refresh_invoices_0263b(i, l_msg);
    END LOOP;
    COMMIT;
END sync_shipments_0263;

PROCEDURE check_quotas_0178 (p_val IN VARCHAR2, p_id IN NUMBER) IS
    l_out NUMBER;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO bm_batches_0178 (priority, id) VALUES (:1, :2)'
            USING p_val || '_juniper_808', p_id;
    END;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM bm_batches_0178 WHERE priority = :1'
        INTO l_out
        USING p_val || '_juniper_808';
    rebuild_ledger_0178b(l_out);
END check_quotas_0178;

end bench_s0025;
/
