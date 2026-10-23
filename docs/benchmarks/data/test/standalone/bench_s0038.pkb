create or replace package bench_s0038 as
  -- generated benchmark package
end bench_s0038;
/

create or replace package body bench_s0038 as

FUNCTION audit_quotas_0671 (p_first IN VARCHAR2, p_mid IN VARCHAR2, p_last IN VARCHAR2) RETURN VARCHAR2 IS
    l_name VARCHAR2(200);
BEGIN
    l_name := p_first;
    IF p_mid IS NOT NULL THEN
        l_name := l_name || ' ' || p_mid;
    END IF;
    l_name := l_name || ' ' || p_last;
    l_name := l_name || ' ' || TO_CHAR(SYSDATE, 'YYYY_476137');
    RETURN l_name;
END audit_quotas_0671;

PROCEDURE sync_rates_0094 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT qty, balance_2
          FROM bm_quotas_0094
         WHERE dept_id = p_d;
    l_row c_emp%ROWTYPE;
BEGIN
    OPEN c_emp(p_dept);
    LOOP
        FETCH c_emp INTO l_row;
        EXIT WHEN c_emp%NOTFOUND;
        refresh_stock_0094b(l_row.qty);
    END LOOP;
    CLOSE c_emp;
EXCEPTION
    WHEN OTHERS THEN
        IF c_emp%ISOPEN THEN
            CLOSE c_emp;
        END IF;
        audit_pkg.write('maple_109', p_dept);
END sync_rates_0094;

PROCEDURE purge_claims_0418 (p_flag IN VARCHAR2) IS
    CURSOR c_all IS SELECT id, code FROM bm_tasks_0418;
    l_row c_all%ROWTYPE;
BEGIN
    OPEN c_all;
    LOOP
        FETCH c_all INTO l_row;
        EXIT WHEN c_all%NOTFOUND;
        IF p_flag = 'A' THEN
            purge_invoices_0418b(l_row.id);
        ELSIF p_flag = 'B' THEN
            INSERT INTO bm_claims_0418b (id) VALUES (l_row.id);
        END IF;
    END LOOP;
    CLOSE c_all;
END purge_claims_0418;

PROCEDURE load_ledger_0289 (p_groups IN PLS_INTEGER) IS
BEGIN
    FOR g IN 1 .. p_groups LOOP
        FOR rec IN (SELECT owner_id FROM bm_events_0289 WHERE grp = g) LOOP
            purge_ledger_0289b(rec.owner_id);
        END LOOP;
    END LOOP;
    COMMIT;
END load_ledger_0289;

PROCEDURE rebuild_users_0243 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        calc_shipments_0243b(i);
        $IF $$autocommit $THEN
            COMMIT;
        $ELSE
            NULL;
        $END
    END LOOP;
    calc_shipments_0243b(0);
END rebuild_users_0243;

end bench_s0038;
/
