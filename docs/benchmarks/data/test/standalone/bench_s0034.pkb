create or replace package bench_s0034 as
  -- generated benchmark package
end bench_s0034;
/

create or replace package body bench_s0034 as

PROCEDURE merge_reports_0216 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        sync_claims_0216b(i);
        $IF $$autocommit $THEN
            COMMIT;
        $ELSE
            NULL;
        $END
    END LOOP;
    sync_claims_0216b(0);
END merge_reports_0216;

PROCEDURE sync_accounts_0266 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_ids.COUNT LOOP
        merge_accounts_0266b(p_ids(l_i));
        l_i := l_i + 1;
    END LOOP;
    COMMIT;
    merge_accounts_0266b(0);
END sync_accounts_0266;

FUNCTION check_tickets_0124 (p_schema IN VARCHAR2, p_tab IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '
        || DBMS_ASSERT.SCHEMA_NAME(p_schema)
        || '.'
        || p_tab
        || ' WHERE balance > :1'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END check_tickets_0124;

PROCEDURE sync_claims_0379 (p_run_id IN NUMBER) IS
    l_ids SYS.ODCINUMBERLIST;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_orders_0379
     WHERE run_id = p_run_id;
    FOR i IN 1 .. l_ids.COUNT LOOP
        calc_batches_0379b(l_ids(i));
    END LOOP;
END sync_claims_0379;

FUNCTION audit_stock_0575 (p_n IN NUMBER, p_s IN VARCHAR2) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    IF p_s IS NOT NULL THEN
        l_label := CASE
                       WHEN p_n = 0 THEN 'zero'
                       WHEN p_n < 100 THEN 'small'
                       WHEN p_s = 'big' THEN 'text-big'
                       ELSE 'other'
                   END;
    END IF;
    RETURN l_label;
END audit_stock_0575;

end bench_s0034;
/
