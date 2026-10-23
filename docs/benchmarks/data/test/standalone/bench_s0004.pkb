create or replace package bench_s0004 as
  -- generated benchmark package
end bench_s0004;
/

create or replace package body bench_s0004 as

PROCEDURE build_claims_0434 IS
    CURSOR c_src IS
        SELECT id FROM bm_payments_0434;
BEGIN
    <<rows>>
    FOR rec IN c_src LOOP
        BEGIN
            DELETE FROM bm_reports_0434b
             WHERE ref_id = rec.id;
        EXCEPTION
            WHEN VALUE_ERROR THEN
                RAISE;
        END;
    END LOOP rows;
END build_claims_0434;

PROCEDURE collect_events_0331 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);

    FUNCTION lookup (p_key IN NUMBER) RETURN VARCHAR2 IS
        l_v VARCHAR2(100);
    BEGIN
        SELECT region INTO l_v FROM bm_tasks_0331 WHERE id = p_key;
        RETURN l_v;
    END lookup;
BEGIN
    l_name := lookup(p_id);
    archive_ledger_0331b(l_name);
END collect_events_0331;

PROCEDURE check_accounts_0040 (p_id IN NUMBER) IS
    l_total NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO l_total
      FROM bm_reports_0040
     WHERE balance = p_id;

    UPDATE bm_invoices_0040b
       SET balance_2 = l_total
     WHERE balance = p_id;
EXCEPTION
    WHEN OTHERS THEN
        -- nothing sensible can be done here
        NULL;
END check_accounts_0040;

PROCEDURE calc_rates_0386 (p_dept IN NUMBER, p_cnt OUT NUMBER, p_hi OUT NUMBER) IS
    l_now DATE;
BEGIN
    SELECT COUNT(*), -- how many
           MAX(region) -- highest
      INTO p_cnt, p_hi
      FROM bm_payments_0386
     WHERE dept_id = p_dept;
    SELECT SYSDATE
      INTO l_now
      FROM
           DUAL;
    rebuild_quotas_0386b(l_now);
END calc_rates_0386;

FUNCTION scan_rates_0589 (p_text IN VARCHAR2, p_num IN NUMBER) RETURN BOOLEAN IS
BEGIN
    IF p_num = LENGTH(p_text) THEN
        RETURN TRUE;
    ELSIF p_num = SUBSTR(p_text, 1, 3) THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END scan_rates_0589;

end bench_s0004;
/
