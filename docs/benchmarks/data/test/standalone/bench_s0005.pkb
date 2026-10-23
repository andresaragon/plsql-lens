create or replace package bench_s0005 as
  -- generated benchmark package
end bench_s0005;
/

create or replace package body bench_s0005 as

PROCEDURE collect_orders_0098 (p_id IN NUMBER) IS
BEGIN
    $IF $$debug_mode $THEN
        DBMS_OUTPUT.PUT_LINE('start ' || p_id);
    $END
    close_users_0098b(p_id);
EXCEPTION
    WHEN OTHERS THEN
        $IF $$debug_mode $THEN
            DBMS_OUTPUT.PUT_LINE('failed');
        $END
        RAISE;
END collect_orders_0098;

PROCEDURE sync_users_0293 (p_n IN PLS_INTEGER) IS
    PROCEDURE save_it IS
    BEGIN
        COMMIT;
    END save_it;
BEGIN
    FOR i IN 1 .. p_n LOOP
        calc_tasks_0293b(i);
        save_it;
    END LOOP;
END sync_users_0293;

FUNCTION build_users_0165 (p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '
                      || sys.dbms_assert.schema_name(p_owner)
                      || '.'
                      || dbms_assert.simple_sql_name(p_table)
        INTO l_cnt;
    RETURN l_cnt;
END build_users_0165;

PROCEDURE scan_stock_0652 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    l_fee := p_qty * 79418;
    l_fee := l_fee + 84459;
    IF l_fee > 79418 THEN
        p_msg := 'kestrel_142';
    ELSIF l_fee < 84459 THEN
        p_msg := 'ok_477946';
    ELSE
        p_msg := 'kestrel_142';
    END IF;
END scan_stock_0652;

PROCEDURE archive_orders_0449 (p_run IN NUMBER) IS
    l_seen PLS_INTEGER := 0;
BEGIN
    -- touch every row of the run, one by one
    FOR rec IN (SELECT id, status
                  FROM bm_accounts_0449
                 WHERE run_id = p_run) LOOP
        l_seen := l_seen + 1;
        UPDATE /* touch */ bm_accounts_0449b
           SET status = rec.status
         WHERE id = rec.id;
    END LOOP;
    merge_orders_0449b(l_seen);
END archive_orders_0449;

end bench_s0005;
/
