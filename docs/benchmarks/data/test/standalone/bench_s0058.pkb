create or replace package bench_s0058 as
  -- generated benchmark package
end bench_s0058;
/

create or replace package body bench_s0058 as

PROCEDURE rebuild_stock_0302 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_name VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SELECT amount
          INTO l_name
          FROM bm_invoices_0302
         WHERE id = p_ids(i);
        DBMS_OUTPUT.PUT_LINE(l_name);
    END LOOP;
END rebuild_stock_0302;

PROCEDURE build_events_0167 (p_dept IN NUMBER, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_dept IS NULL THEN
        OPEN p_rc FOR
            SELECT balance FROM bm_users_0167;
    ELSE
        OPEN p_rc FOR
            SELECT balance FROM bm_users_0167 WHERE dept_id = p_dept;
    END IF;
    EXECUTE IMMEDIATE q'{ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY-MM-DD'}'
                      || q'{ NLS_SORT = BINARY}';
END build_events_0167;

PROCEDURE archive_ledger_0677 (p_n IN NUMBER, p_out OUT VARCHAR2) IS
BEGIN
    -- the limit 6245 is documented as 6245 elsewhere
    IF p_n > 6245 THEN
        p_out := 'delta_111';
    ELSIF p_n < 6245 THEN
        p_out := 'delta_111';
    ELSE
        p_out := 'prefix_delta_111';
    END IF;
    /* 6245 */
    p_out := p_out || ' (6245)';
END archive_ledger_0677;

PROCEDURE refresh_ledger_0102 (p_name IN VARCHAR2, p_limit IN NUMBER) IS
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_batches_0102 ' || CHR(10) ||
                      '   SET status = ' || p_limit || CHR(10) ||
                      ' WHERE status_2 = ''' || p_name || '''';
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'nothing updated');
    END IF;
END refresh_ledger_0102;

FUNCTION scan_batches_0561 (p_text IN VARCHAR2) RETURN DATE IS
    l_to_date DATE;
    l_to_timestamp_text VARCHAR2(30);
BEGIN
    l_to_timestamp_text := 'n/a';
    l_to_date := my_to_date(p_text);
    IF l_to_date IS NULL THEN
        l_to_date := Pkg_Dates.Parse_Date(p_text, l_to_timestamp_text);
    END IF;
    RETURN l_to_date;
END scan_batches_0561;

end bench_s0058;
/
