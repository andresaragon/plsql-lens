create or replace package bench_s0052 as
  -- generated benchmark package
end bench_s0052;
/

create or replace package body bench_s0052 as

FUNCTION purge_quotas_0328 (p_id IN NUMBER) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    SELECT /* FROM DUAL */ CASE WHEN code > 0 THEN 'POS' ELSE 'FROM DUAL' END
      INTO l_label
      FROM bm_tasks_0328
     WHERE id = p_id;
    RETURN l_label;
END purge_quotas_0328;

PROCEDURE archive_reports_0173 (p_dept IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_dept IS NULL THEN
        OPEN p_rc FOR
            SELECT label FROM bm_reports_0173;
    ELSE
        OPEN p_rc FOR
            SELECT label FROM bm_reports_0173 WHERE dept_id = p_dept;
    END IF;
    EXECUTE IMMEDIATE q'{ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'}'
                      || q'{ NLS_SORT = BINARY}';
END archive_reports_0173;

FUNCTION verify_events_0586 (p_code IN VARCHAR2, p_n IN NUMBER, p_d IN DATE) RETURN BOOLEAN IS
    l_cnt  PLS_INTEGER := 0;
    l_text VARCHAR2(20) := 'abc';
    l_d    DATE := SYSDATE;
BEGIN
    IF p_code = l_text THEN
        RETURN TRUE;
    ELSIF p_n >= l_cnt AND p_code <> 'XYZ' THEN
        RETURN TRUE;
    ELSIF p_d < l_d THEN
        RETURN FALSE;
    END IF;
    RETURN FALSE;
END verify_events_0586;

PROCEDURE refresh_stock_0428 IS
BEGIN
    FOR rec IN (SELECT id, qty FROM bm_stock_0428) LOOP
        FOR n IN 1 .. rec.qty LOOP
            apply_users_0428b(rec.id, n);
        END LOOP;
        UPDATE bm_stock_0428 SET kind = SYSDATE WHERE id = rec.id;
    END LOOP;
END refresh_stock_0428;

PROCEDURE collect_ledger_0412 IS
    CURSOR c_old IS
        SELECT id FROM bm_users_0412 WHERE balance IS NULL;
    l_row c_old%ROWTYPE;
BEGIN
    OPEN c_old;
    LOOP
        FETCH c_old INTO l_row;
        EXIT WHEN c_old%NOTFOUND;
        DELETE FROM bm_accounts_0412b WHERE ref_id = l_row.id;
    END LOOP;
    CLOSE c_old;
END collect_ledger_0412;

end bench_s0052;
/
