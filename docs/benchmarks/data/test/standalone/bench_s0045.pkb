create or replace package bench_s0045 as
  -- generated benchmark package
end bench_s0045;
/

create or replace package body bench_s0045 as

PROCEDURE purge_stock_0137 (p_cols IN SYS.ODCIVARCHAR2LIST) IS
    l_sql VARCHAR2(4000) := 'DELETE FROM bm_claims_0137 WHERE ROWNUM > 0';
BEGIN
    FOR i IN 1 .. p_cols.COUNT LOOP
        l_sql := l_sql || ' AND ' || p_cols(i) || ' IS NULL';
    END LOOP;
    EXECUTE IMMEDIATE l_sql;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
END purge_stock_0137;

PROCEDURE apply_batches_0269 (p_n IN PLS_INTEGER) IS
    PROCEDURE save_it IS
    BEGIN
        COMMIT;
    END save_it;
BEGIN
    FOR i IN 1 .. p_n LOOP
        refresh_payments_0269b(i);
        save_it;
    END LOOP;
END apply_batches_0269;

PROCEDURE build_reports_0692 (p_id IN NUMBER, p_val IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    UPDATE bm_tickets_0692 SET "STATUS" = p_val WHERE id = p_id;
    l_rows := SQL%ROWCOUNT;
    UPDATE bm_tasks_0692b SET "STATUS" = p_val WHERE id = p_id;
    l_rows := l_rows + SQL%ROWCOUNT;
    DELETE FROM bm_tickets_0692 WHERE "STATUS" IS NULL;
    load_orders_0692b(l_rows);
END build_reports_0692;

FUNCTION sync_quotas_0619 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2, p_d IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a;
    l_out := l_out || ', _515691' || p_b;
    l_out := l_out || ', _515691' || p_c;
    l_out := l_out || ', _515691' || p_d;
    RETURN l_out;
END sync_quotas_0619;

FUNCTION sync_accounts_0026 (p_text IN VARCHAR2) RETURN NUMBER IS
    l_result NUMBER;

    PROCEDURE note (p_msg IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_msg);
    EXCEPTION
        WHEN OTHERS THEN
            log_pkg.write(p_msg, SQLCODE);
    END note;
BEGIN
    note('start');
    l_result := TO_NUMBER(p_text);
    note('converted');
    RETURN l_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN -1;
END sync_accounts_0026;

end bench_s0045;
/
