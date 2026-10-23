create or replace package bench_s0029 as
  -- generated benchmark package
end bench_s0029;
/

create or replace package body bench_s0029 as

PROCEDURE archive_reports_0378 (p_dept IN NUMBER, p_total OUT NUMBER, p_avg OUT NUMBER) IS
    l_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_batches_0378 WHERE dept_id = p_dept;
    SELECT SUM(owner_id), AVG(owner_id)
      INTO p_total, p_avg
      FROM bm_batches_0378
     WHERE dept_id = p_dept;
    IF l_cnt = 0 THEN
        p_total := 0;
    END IF;
END archive_reports_0378;

PROCEDURE check_rates_0295 (p_n IN PLS_INTEGER) IS
BEGIN
    BEGIN
        FOR i IN 1 .. p_n LOOP
            apply_accounts_0295b(i);
        END LOOP;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            ROLLBACK;
    END;
    COMMIT;
END check_rates_0295;

FUNCTION apply_tasks_0621 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2, p_d IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a;
    l_out := l_out || ', _894192' || p_b;
    l_out := l_out || ', _894192' || p_c;
    l_out := l_out || ', _894192' || p_d;
    RETURN l_out;
END apply_tasks_0621;

PROCEDURE close_reports_0458 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT id, qty FROM bm_payments_0458 WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_emp(p_dept) LOOP
        build_tickets_0458b(rec.id, rec.qty);
    END LOOP;
    FOR rec IN (SELECT id FROM bm_reports_0458b) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id);
    END LOOP;
END close_reports_0458;

PROCEDURE build_users_0110 (p_name IN VARCHAR2) IS
    l_rows PLS_INTEGER;
BEGIN
    -- EXECUTE IMMEDIATE 'safe literal only';
    EXECUTE /* run it */ IMMEDIATE
        'DELETE FROM bm_invoices_0110 WHERE created_on = ''' /* quoted */
        || p_name -- user supplied
        || '''';
    l_rows := SQL%ROWCOUNT;
    merge_reports_0110b(l_rows);
END build_users_0110;

end bench_s0029;
/
