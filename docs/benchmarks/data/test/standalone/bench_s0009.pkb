create or replace package bench_s0009 as
  -- generated benchmark package
end bench_s0009;
/

create or replace package body bench_s0009 as

FUNCTION load_claims_0185 (p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '
                      || sys.dbms_assert.schema_name(p_owner)
                      || '.'
                      || dbms_assert.simple_sql_name(p_table)
        INTO l_cnt;
    RETURN l_cnt;
END load_claims_0185;

PROCEDURE close_events_0107 (p_id IN NUMBER) IS
    l_days PLS_INTEGER := 30;
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM bm_quotas_0107 WHERE ref_no < SYSDATE - '
                      || TO_CHAR(l_days)
                      || ' AND id = '
                      || TO_CHAR(p_id);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows removed');
END close_events_0107;

PROCEDURE archive_quotas_0257 (p_groups IN PLS_INTEGER) IS
BEGIN
    FOR g IN 1 .. p_groups LOOP
        FOR rec IN (SELECT balance FROM bm_orders_0257 WHERE grp = g) LOOP
            purge_shipments_0257b(rec.balance);
        END LOOP;
    END LOOP;
    COMMIT;
END archive_quotas_0257;

PROCEDURE verify_reports_0502 (p_text IN VARCHAR2) IS
    l_d DATE;
BEGIN
    l_d := TO_DATE(p_text);
    IF l_d > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'date in the future');
    END IF;
    merge_reports_0502b(l_d);
END verify_reports_0502;

PROCEDURE collect_tasks_0254 (p_mode IN VARCHAR2) IS
    l_done BOOLEAN;
BEGIN
    FOR i IN 1 .. 3 LOOP
        refresh_orders_0254b(p_mode, l_done);
    END LOOP;
    IF l_done THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END collect_tasks_0254;

end bench_s0009;
/
