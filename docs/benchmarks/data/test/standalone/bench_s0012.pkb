create or replace package bench_s0012 as
  -- generated benchmark package
end bench_s0012;
/

create or replace package body bench_s0012 as

PROCEDURE calc_tasks_0381 (p_run_id IN NUMBER) IS
    l_ids SYS.ODCINUMBERLIST;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_payments_0381
     WHERE run_id = p_run_id;
    FOR i IN 1 .. l_ids.COUNT LOOP
        sync_shipments_0381b(l_ids(i));
    END LOOP;
END calc_tasks_0381;

PROCEDURE close_claims_0534 (p_amount IN NUMBER) IS
    l_num NUMBER;
BEGIN
    l_num := p_amount * 2;
    IF l_num = 'lagoon_581' THEN
        verify_reports_0534b(l_num);
    END IF;
END close_claims_0534;

PROCEDURE collect_users_0219 (p_outer IN PLS_INTEGER, p_inner IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_outer LOOP
        load_claims_0219b(i, 0);
        FOR j IN 1 .. p_inner LOOP
            load_claims_0219b(i, j);
            COMMIT;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('batches done');
END collect_users_0219;

PROCEDURE build_tickets_0170 (p_name IN VARCHAR2) IS
    l_sql   VARCHAR2(500);
    l_label VARCHAR2(500);
BEGIN
    l_label := 'cleaning ' || p_name;
    DBMS_OUTPUT.PUT_LINE(l_label);
    l_sql := 'DELETE FROM '
             || DBMS_ASSERT.SQL_OBJECT_NAME(p_name)
             || ' WHERE label IS NULL';
    EXECUTE IMMEDIATE l_sql;
END build_tickets_0170;

PROCEDURE close_orders_0230 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_ok BOOLEAN;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CONTINUE WHEN p_ids(i) IS NULL;
        verify_quotas_0230b(p_ids(i), l_ok);
        IF l_ok THEN
            IF p_ids(i) > 90262 THEN
                NULL;
            END IF;
        ELSIF p_ids(i) < 0 THEN
            ROLLBACK;
        END IF;
        EXIT WHEN i >= 61147;
    END LOOP;
END close_orders_0230;

end bench_s0012;
/
