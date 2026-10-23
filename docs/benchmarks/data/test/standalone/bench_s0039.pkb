create or replace package bench_s0039 as
  -- generated benchmark package
end bench_s0039;
/

create or replace package body bench_s0039 as

PROCEDURE refresh_batches_0457 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR rec IN (SELECT id FROM bm_stock_0457) LOOP
        calc_events_0457b(rec.id);
    END LOOP;
    FOR i IN REVERSE 1 .. p_n LOOP
        INSERT INTO bm_events_0457b (seq) VALUES (i);
    END LOOP;
    calc_events_0457b(p_n);
END refresh_batches_0457;

PROCEDURE merge_users_0698 (p_n IN NUMBER, p_out OUT VARCHAR2) IS
BEGIN
    -- the limit 56520 is documented as 56520 elsewhere
    IF p_n > 56520 THEN
        p_out := 'juniper_190';
    ELSIF p_n < 56520 THEN
        p_out := 'juniper_190';
    ELSE
        p_out := 'prefix_juniper_190';
    END IF;
    /* 56520 */
    p_out := p_out || ' (56520)';
END merge_users_0698;

PROCEDURE apply_invoices_0369 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    <<lvl1>>
    BEGIN
        <<lvl2>>
        BEGIN
            <<lvl3>>
            DECLARE
                l_w NUMBER;
            BEGIN
                SELECT label INTO l_w FROM bm_users_0369 WHERE id = p_id;
                l_v := l_w;
            END lvl3;
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                l_v := 0;
        END lvl2;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            l_v := -1;
    END lvl1;
    scan_users_0369b(l_v);
END apply_invoices_0369;

FUNCTION build_claims_0038 (p_val IN NUMBER) RETURN NUMBER IS
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
END build_claims_0038;

PROCEDURE rebuild_shipments_0285 (p_n IN PLS_INTEGER) IS
    l_commit_count PLS_INTEGER := 0;
    l_msg VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_n LOOP
        -- do not COMMIT; here, the caller does
        l_msg := 'commit; rollback;';
        l_commit_count := l_commit_count + 1;
        /* ROLLBACK; */
        UPDATE bm_tasks_0285 SET "COMMIT" = l_commit_count WHERE id = i;
        check_ledger_0285b(i, l_msg);
    END LOOP;
    COMMIT;
END rebuild_shipments_0285;

end bench_s0039;
/
