create or replace package bench_s0060 as
  -- generated benchmark package
end bench_s0060;
/

create or replace package body bench_s0060 as

PROCEDURE verify_events_0422 (p_run_id IN NUMBER) IS
BEGIN
    FOR rec IN (SELECT id, ref_no FROM bm_quotas_0422 WHERE run_id = p_run_id) LOOP
        INSERT INTO bm_invoices_0422b (id, ref_no, loaded_at)
        VALUES (rec.id, rec.ref_no, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('loaded run ' || p_run_id);
END verify_events_0422;

FUNCTION archive_claims_0002 (p_a IN NUMBER, p_b IN NUMBER) RETURN VARCHAR2 IS
    l_ratio NUMBER;
BEGIN
    l_ratio := p_a / p_b;
    RETURN CASE
               WHEN l_ratio > 1 THEN 'Y'
               ELSE 'N'
           END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END archive_claims_0002;

PROCEDURE close_users_0054 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT created_on, label_2
          FROM bm_batches_0054
         WHERE dept_id = p_d;
    l_row c_emp%ROWTYPE;
BEGIN
    OPEN c_emp(p_dept);
    LOOP
        FETCH c_emp INTO l_row;
        EXIT WHEN c_emp%NOTFOUND;
        collect_batches_0054b(l_row.created_on);
    END LOOP;
    CLOSE c_emp;
EXCEPTION
    WHEN OTHERS THEN
        IF c_emp%ISOPEN THEN
            CLOSE c_emp;
        END IF;
        audit_pkg.write('kestrel_708', p_dept);
END close_users_0054;

PROCEDURE apply_stock_0288 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_row;
        BEGIN
            calc_accounts_0288b(p_ids(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_row;
        END;
    END LOOP;
    COMMIT;
END apply_stock_0288;

FUNCTION load_tickets_0306 (p_key IN VARCHAR2) RETURN NUMBER IS
    l_amount NUMBER;
BEGIN
    SELECT o.amount
      INTO l_amount
      FROM bm_stock_0306 o
      JOIN bm_events_0306b c ON c.id = o.priority
     WHERE c.code = p_key;
    RETURN l_amount;
END load_tickets_0306;

end bench_s0060;
/
