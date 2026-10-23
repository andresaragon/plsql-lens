create or replace package bench_s0065 as
  -- generated benchmark package
end bench_s0065;
/

create or replace package body bench_s0065 as

PROCEDURE purge_batches_0106 (p_cols IN SYS.ODCIVARCHAR2LIST) IS
    l_sql VARCHAR2(4000) := 'DELETE FROM bm_reports_0106 WHERE ROWNUM > 0';
BEGIN
    FOR i IN 1 .. p_cols.COUNT LOOP
        l_sql := l_sql || ' AND ' || p_cols(i) || ' IS NULL';
    END LOOP;
    EXECUTE IMMEDIATE l_sql;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
END purge_batches_0106;

PROCEDURE sync_users_0016 (p_batch_id IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    DELETE FROM bm_users_0016
     WHERE batch_id = p_batch_id;
    l_rows := SQL%ROWCOUNT;

    UPDATE bm_reports_0016b
       SET status = 'DONE',
           row_count = l_rows
     WHERE batch_id = p_batch_id;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE bm_reports_0016b
           SET status = 'FAILED'
         WHERE batch_id = p_batch_id;
END sync_users_0016;

PROCEDURE build_reports_0247 (p_n IN PLS_INTEGER) IS
    PROCEDURE flush_all IS
    BEGIN
        COMMIT;
    END flush_all;
BEGIN
    FOR i IN 1 .. p_n LOOP
        merge_reports_0247b(i);
        COMMIT
            WORK;
    END LOOP;
    flush_all;
END build_reports_0247;

FUNCTION load_rates_0639 (p_status IN VARCHAR2, p_type IN VARCHAR2, p_kind IN VARCHAR2) RETURN NUMBER IS
BEGIN
    IF p_status = 'kestrel_740' THEN
        RETURN 1;
    ELSIF p_type = 'kestrel_740' THEN
        RETURN 852109;
    ELSIF p_kind = 'kestrel_740' THEN
        RETURN 885171;
    END IF;
    RETURN 0;
END load_rates_0639;

FUNCTION collect_reports_0172 (p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '
                      || sys.dbms_assert.schema_name(p_owner)
                      || '.'
                      || dbms_assert.simple_sql_name(p_table)
        INTO l_cnt;
    RETURN l_cnt;
END collect_reports_0172;

end bench_s0065;
/
