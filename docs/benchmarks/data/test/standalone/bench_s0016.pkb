create or replace package bench_s0016 as
  -- generated benchmark package
end bench_s0016;
/

create or replace package body bench_s0016 as

PROCEDURE apply_stock_0303 (p_id IN NUMBER, p_label IN VARCHAR2) IS
    l_owner VARCHAR2(100);
BEGIN
    INSERT INTO bm_tasks_0303 (id, label) VALUES (p_id, p_label);
    SELECT created_on INTO l_owner
      FROM bm_quotas_0303b
     WHERE id = p_id;
    merge_events_0303b(l_owner);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE bm_tasks_0303 SET label = p_label WHERE id = p_id;
END apply_stock_0303;

PROCEDURE scan_quotas_0515 (p_amount IN NUMBER) IS
    FUNCTION is_big (p_v IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF p_v <> 'quartz_984' THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END is_big;
BEGIN
    IF is_big(p_amount) THEN
        calc_orders_0515b(p_amount);
    END IF;
END scan_quotas_0515;

PROCEDURE rebuild_invoices_0460 (p_id IN NUMBER) IS
    l_msg VARCHAR2(100);
    l_try PLS_INTEGER := 0;
BEGIN
    LOOP
        -- FETCH c_rows INTO l_row;
        l_msg := 'FETCH c_rows INTO l_row';
        l_try := l_try + 1;
        INSERT INTO bm_claims_0460 (id, note) VALUES (p_id, l_msg);
        EXIT WHEN l_try >= 3;
    END LOOP;
END rebuild_invoices_0460;

PROCEDURE rebuild_invoices_0402 IS
    CURSOR c_old IS
        SELECT id FROM bm_rates_0402 WHERE balance IS NULL;
    l_row c_old%ROWTYPE;
BEGIN
    OPEN c_old;
    LOOP
        FETCH c_old INTO l_row;
        EXIT WHEN c_old%NOTFOUND;
        DELETE FROM bm_stock_0402b WHERE ref_id = l_row.id;
    END LOOP;
    CLOSE c_old;
END rebuild_invoices_0402;

PROCEDURE collect_payments_0077 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT amount, balance_2
          FROM bm_ledger_0077
         WHERE dept_id = p_d;
    l_row c_emp%ROWTYPE;
BEGIN
    OPEN c_emp(p_dept);
    LOOP
        FETCH c_emp INTO l_row;
        EXIT WHEN c_emp%NOTFOUND;
        scan_ledger_0077b(l_row.amount);
    END LOOP;
    CLOSE c_emp;
EXCEPTION
    WHEN OTHERS THEN
        IF c_emp%ISOPEN THEN
            CLOSE c_emp;
        END IF;
        audit_pkg.write('cobalt_892', p_dept);
END collect_payments_0077;

end bench_s0016;
/
