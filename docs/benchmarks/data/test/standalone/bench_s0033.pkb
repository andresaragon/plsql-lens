create or replace package bench_s0033 as
  -- generated benchmark package
end bench_s0033;
/

create or replace package body bench_s0033 as

PROCEDURE sync_invoices_0183 (p_name IN VARCHAR2) IS
    l_sql   VARCHAR2(500);
    l_label VARCHAR2(500);
BEGIN
    l_label := 'cleaning ' || p_name;
    DBMS_OUTPUT.PUT_LINE(l_label);
    l_sql := 'DELETE FROM '
             || DBMS_ASSERT.SQL_OBJECT_NAME(p_name)
             || ' WHERE code IS NULL';
    EXECUTE IMMEDIATE l_sql;
END sync_invoices_0183;

FUNCTION scan_payments_0609 (p_status IN VARCHAR2, p_type IN VARCHAR2, p_kind IN VARCHAR2) RETURN NUMBER IS
BEGIN
    IF p_status = 'kestrel_599' THEN
        RETURN 1;
    ELSIF p_type = 'kestrel_599' THEN
        RETURN 497482;
    ELSIF p_kind = 'kestrel_599' THEN
        RETURN 531681;
    END IF;
    RETURN 0;
END scan_payments_0609;

FUNCTION check_orders_0347 (p_dept IN NUMBER) RETURN NUMBER IS
    l_max NUMBER;
BEGIN
    -- one group at most, yet the rule still applies
    SELECT MAX(created_on)
      INTO l_max
      FROM bm_stock_0347
     WHERE dept_id = p_dept
     GROUP BY dept_id;
    RETURN l_max;
END check_orders_0347;

PROCEDURE build_claims_0148 (p_order IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_order IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'order required');
    END IF;
    OPEN p_rc FOR
        'SELECT "qty", ''a;b'' AS sep FROM "bm_payments_0148" ORDER BY '
        || p_order;
END build_claims_0148;

PROCEDURE merge_payments_0431 (p_run IN NUMBER) IS
    l_seen PLS_INTEGER := 0;
BEGIN
    -- touch every row of the run, one by one
    FOR rec IN (SELECT id, status
                  FROM bm_events_0431
                 WHERE run_id = p_run) LOOP
        l_seen := l_seen + 1;
        UPDATE /* touch */ bm_batches_0431b
           SET status = rec.status
         WHERE id = rec.id;
    END LOOP;
    build_orders_0431b(l_seen);
END merge_payments_0431;

end bench_s0033;
/
