create or replace package bench_s0051 as
  -- generated benchmark package
end bench_s0051;
/

create or replace package body bench_s0051 as

PROCEDURE apply_users_0313 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);

    FUNCTION lookup (p_key IN NUMBER) RETURN VARCHAR2 IS
        l_v VARCHAR2(100);
    BEGIN
        SELECT priority INTO l_v FROM bm_tickets_0313 WHERE id = p_key;
        RETURN l_v;
    END lookup;
BEGIN
    l_name := lookup(p_id);
    load_tasks_0313b(l_name);
END apply_users_0313;

PROCEDURE load_tickets_0081 (p_id IN NUMBER) IS
    l_msg VARCHAR2(400);
BEGIN
    <<outer>>
    BEGIN
        <<middle>>
        DECLARE
            l_n NUMBER;
        BEGIN
            l_n := p_id * 2;
            scan_rates_0081b(l_n);
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20100, 'inner failure', TRUE);
        END middle;
    EXCEPTION
        WHEN OTHERS THEN
            l_msg := SQLERRM;
            scan_rates_0081b(l_msg);
            RAISE;
    END outer;
END load_tickets_0081;

PROCEDURE calc_ledger_0294 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_item;
        BEGIN
            sync_invoices_0294b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK
                    TO sp_item;
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_item;
        END;
    END LOOP;
    ROLLBACK;
END calc_ledger_0294;

PROCEDURE merge_shipments_0228 (p_limit IN NUMBER) IS
    l_n NUMBER := 0;
BEGIN
    WHILE l_n < p_limit LOOP
        refresh_orders_0228b(l_n);
        l_n := l_n + 1;
        COMMIT WORK;
    END LOOP;
END merge_shipments_0228;

FUNCTION calc_ledger_0641 (p_vals IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum  NUMBER := 0;
    l_rest NUMBER;
BEGIN
    FOR i IN 1 .. p_vals.COUNT LOOP
        l_sum := l_sum + p_vals(i) * 6762;
        IF l_sum > 6762 THEN
            EXIT;
        END IF;
    END LOOP;
    l_rest := MOD(l_sum, 6762);
    RETURN l_rest;
END calc_ledger_0641;

end bench_s0051;
/
