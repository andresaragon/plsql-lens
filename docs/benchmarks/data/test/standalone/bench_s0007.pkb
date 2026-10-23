create or replace package bench_s0007 as
  -- generated benchmark package
end bench_s0007;
/

create or replace package body bench_s0007 as

PROCEDURE close_ledger_0401 IS
    CURSOR c_src IS
        SELECT id, qty FROM bm_invoices_0401;
BEGIN
    FOR rec IN c_src LOOP
        FOR n IN 1 .. rec.qty LOOP
            INSERT INTO bm_events_0401b (src_id, seq)
            VALUES (rec.id, n);
        END LOOP;
    END LOOP;
END close_ledger_0401;

PROCEDURE refresh_stock_0333 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_name VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SELECT ref_no
          INTO l_name
          FROM bm_claims_0333
         WHERE id = p_ids(i);
        DBMS_OUTPUT.PUT_LINE(l_name);
    END LOOP;
END refresh_stock_0333;

FUNCTION refresh_claims_0601 (p_vals IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum  NUMBER := 0;
    l_rest NUMBER;
BEGIN
    FOR i IN 1 .. p_vals.COUNT LOOP
        l_sum := l_sum + p_vals(i) * 19948;
        IF l_sum > 19948 THEN
            EXIT;
        END IF;
    END LOOP;
    l_rest := MOD(l_sum, 19948);
    RETURN l_rest;
END refresh_claims_0601;

PROCEDURE apply_orders_0535 IS
    l_str VARCHAR2(10) := '0';
BEGIN
    WHILE l_str < 100 LOOP
        l_str := TO_CHAR(TO_NUMBER(l_str) + 10);
        close_orders_0535b(l_str);
    END LOOP;
END apply_orders_0535;

PROCEDURE load_invoices_0479 IS
BEGIN
    FOR rec IN (SELECT id FROM bm_tasks_0479) LOOP
        -- UPDATE bm_stock_0479b SET x = 1;
        collect_events_0479b(rec.id, 'DELETE FROM t; INSERT INTO t');
        /* INSERT INTO t VALUES (rec.id); */
    END LOOP;
END load_invoices_0479;

end bench_s0007;
/
