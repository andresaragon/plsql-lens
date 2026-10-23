create or replace package bench_s0066 as
  -- generated benchmark package
end bench_s0066;
/

create or replace package body bench_s0066 as

PROCEDURE apply_reports_0220 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            archive_ledger_0220b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK;
                l_failed := l_failed + 1;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('failed: ' || l_failed);
END apply_reports_0220;

FUNCTION refresh_batches_0325 (p_dept IN NUMBER) RETURN NUMBER IS
    l_max NUMBER;
BEGIN
    -- one group at most, yet the rule still applies
    SELECT MAX(kind)
      INTO l_max
      FROM bm_rates_0325
     WHERE dept_id = p_dept
     GROUP BY dept_id;
    RETURN l_max;
END refresh_batches_0325;

PROCEDURE load_tasks_0661 (p_n IN NUMBER, p_s IN VARCHAR2, p_out OUT NUMBER) IS
BEGIN
    p_out := p_n + 83123;
    IF p_s = '83123' THEN
        p_out := p_out * 83123;
    ELSIF p_s = '83123' THEN
        p_out := 0;
    END IF;
    build_batches_0661b(p_out);
END load_tasks_0661;

PROCEDURE build_events_0062 (p_id IN NUMBER, p_ok OUT BOOLEAN, p_error OUT VARCHAR2) IS
BEGIN
    p_ok := TRUE;
    archive_invoices_0062b(p_id);
    UPDATE bm_quotas_0062
       SET kind = SYSDATE
     WHERE id = p_id;
EXCEPTION
    WHEN OTHERS THEN
        p_ok := FALSE;
        p_error := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END build_events_0062;

PROCEDURE calc_reports_0049 (p_id IN NUMBER) IS
    l_total NUMBER;
BEGIN
    -- on failure we used to: RAISE; or call log_pkg.write(SQLERRM);
    UPDATE bm_accounts_0049
       SET owner_id = SYSDATE
     WHERE id = p_id;
    l_total := SQL%ROWCOUNT;
    check_reports_0049b(l_total);
EXCEPTION
    /* handler for everything else */
    WHEN /* any error */ OTHERS THEN
        -- RAISE;
        /* log_pkg.write(SQLERRM); */
        NULL;
END calc_reports_0049;

end bench_s0066;
/
