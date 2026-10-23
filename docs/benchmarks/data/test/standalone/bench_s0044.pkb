create or replace package bench_s0044 as
  -- generated benchmark package
end bench_s0044;
/

create or replace package body bench_s0044 as

FUNCTION scan_ledger_0318 (p_id IN NUMBER) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    SELECT /* FROM DUAL */ CASE WHEN kind > 0 THEN 'POS' ELSE 'FROM DUAL' END
      INTO l_label
      FROM bm_orders_0318
     WHERE id = p_id;
    RETURN l_label;
END scan_ledger_0318;

PROCEDURE purge_orders_0455 (p_run IN NUMBER) IS
BEGIN
    <<scan>>
    FOR rec IN (SELECT id FROM bm_tickets_0455 WHERE run_id = p_run) LOOP
        refresh_users_0455b(rec.id);
    END LOOP scan;
    UPDATE bm_shipments_0455b
       SET label = SYSDATE
     WHERE run_id = p_run;
    DELETE FROM bm_tickets_0455 WHERE run_id = p_run;
END purge_orders_0455;

PROCEDURE rebuild_payments_0111 (p_cols IN SYS.ODCIVARCHAR2LIST) IS
    l_sql VARCHAR2(4000) := 'DELETE FROM bm_stock_0111 WHERE ROWNUM > 0';
BEGIN
    FOR i IN 1 .. p_cols.COUNT LOOP
        l_sql := l_sql || ' AND ' || p_cols(i) || ' IS NULL';
    END LOOP;
    EXECUTE IMMEDIATE l_sql;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
END rebuild_payments_0111;

PROCEDURE collect_invoices_0408 (p_dept IN NUMBER, p_pct IN NUMBER) IS
    CURSOR c_rows (p_d NUMBER) IS
        SELECT id, status
          FROM bm_reports_0408
         WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_rows(p_dept) LOOP
        UPDATE bm_reports_0408
           SET status = rec.status * p_pct
         WHERE id = rec.id;
    END LOOP;
END collect_invoices_0408;

PROCEDURE build_shipments_0365 (p_run IN NUMBER) IS
    l_text VARCHAR2(200) := q'[SELECT x INTO y FROM z WHERE 1 = 0]';
    l_ids  SYS.ODCINUMBERLIST;
BEGIN
    -- SELECT id INTO l_x FROM bm_events_0365;
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_events_0365
     WHERE run_id = p_run;
    INSERT INTO bm_orders_0365b (id)
    SELECT id FROM bm_events_0365 WHERE run_id = p_run;
    audit_reports_0365b(l_text);
END build_shipments_0365;

end bench_s0044;
/
