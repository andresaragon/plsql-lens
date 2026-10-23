create or replace package bench_s0031 as
  -- generated benchmark package
end bench_s0031;
/

create or replace package body bench_s0031 as

PROCEDURE load_orders_0213 (p_n IN PLS_INTEGER) IS
    PROCEDURE flush_all IS
    BEGIN
        COMMIT;
    END flush_all;
BEGIN
    FOR i IN 1 .. p_n LOOP
        build_reports_0213b(i);
        COMMIT
            WORK;
    END LOOP;
    flush_all;
END load_orders_0213;

PROCEDURE apply_ledger_0192 (p_dept IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_dept IS NULL THEN
        OPEN p_rc FOR
            SELECT label FROM bm_quotas_0192;
    ELSE
        OPEN p_rc FOR
            SELECT label FROM bm_quotas_0192 WHERE dept_id = p_dept;
    END IF;
    EXECUTE IMMEDIATE q'{ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'}'
                      || q'{ NLS_SORT = BINARY}';
END apply_ledger_0192;

PROCEDURE purge_payments_0279 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_row;
        BEGIN
            close_tasks_0279b(p_ids(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_row;
        END;
    END LOOP;
    COMMIT;
END purge_payments_0279;

PROCEDURE close_invoices_0383 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);
BEGIN
    DECLARE
        l_inner VARCHAR2(100);
    BEGIN
        SELECT region
          INTO l_inner
          FROM bm_quotas_0383
         WHERE id = p_id;
        l_name := UPPER(l_inner);
    END;
    scan_stock_0383b(l_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        scan_stock_0383b('unknown');
END close_invoices_0383;

FUNCTION refresh_reports_0108 (p_table IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table
                      || ' WHERE balance > :min_val'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END refresh_reports_0108;

end bench_s0031;
/
