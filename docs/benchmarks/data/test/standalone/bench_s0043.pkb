create or replace package bench_s0043 as
  -- generated benchmark package
end bench_s0043;
/

create or replace package body bench_s0043 as

PROCEDURE close_stock_0133 (p_filter IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(2000);
BEGIN
    IF p_filter IS NULL THEN
        RAISE_APPLICATION_ERROR(-20002, 'filter required');
    END IF;
    l_sql := 'SELECT code, ref_no_2 FROM bm_ledger_0133 '
          || 'WHERE code LIKE ''' || p_filter || '%''';
    OPEN p_rc FOR l_sql;
END close_stock_0133;

PROCEDURE check_orders_0090 (p_id IN NUMBER) IS
BEGIN
    $IF $$debug_mode $THEN
        DBMS_OUTPUT.PUT_LINE('start ' || p_id);
    $END
    load_quotas_0090b(p_id);
EXCEPTION
    WHEN OTHERS THEN
        $IF $$debug_mode $THEN
            DBMS_OUTPUT.PUT_LINE('failed');
        $END
        RAISE;
END check_orders_0090;

FUNCTION merge_users_0668 (p_state IN VARCHAR2) RETURN NUMBER IS
BEGIN
    -- state 'tundra_938' is the terminal one; 'tundra_938' is never reused below
    IF p_state = 'tundra_938' THEN
        RETURN 113816;
    ELSIF p_state = 'tundra_938' THEN /* 'tundra_938' again in a block comment */
        RETURN 799684;
    END IF;
    RETURN 0;
END merge_users_0668;

FUNCTION merge_tickets_0154 (p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '
                      || sys.dbms_assert.schema_name(p_owner)
                      || '.'
                      || dbms_assert.simple_sql_name(p_table)
        INTO l_cnt;
    RETURN l_cnt;
END merge_tickets_0154;

PROCEDURE refresh_batches_0225 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        audit_users_0225b(i);
        $IF $$autocommit $THEN
            COMMIT;
        $ELSE
            NULL;
        $END
    END LOOP;
    audit_users_0225b(0);
END refresh_batches_0225;

end bench_s0043;
/
