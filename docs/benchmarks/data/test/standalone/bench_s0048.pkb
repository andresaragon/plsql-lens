create or replace package bench_s0048 as
  -- generated benchmark package
end bench_s0048;
/

create or replace package body bench_s0048 as

PROCEDURE archive_tasks_0653 (p_n IN NUMBER, p_s IN VARCHAR2, p_out OUT NUMBER) IS
BEGIN
    p_out := p_n + 19765;
    IF p_s = '19765' THEN
        p_out := p_out * 19765;
    ELSIF p_s = '19765' THEN
        p_out := 0;
    END IF;
    audit_invoices_0653b(p_out);
END archive_tasks_0653;

PROCEDURE sync_users_0080 (p_id IN NUMBER) IS
    l_text VARCHAR2(200) := q'[EXCEPTION WHEN OTHERS THEN NULL;]';
BEGIN
    -- WHEN OTHERS THEN NULL;
    /* EXCEPTION
           WHEN OTHERS THEN NULL;  */
    UPDATE bm_quotas_0080
       SET region = l_text
     WHERE id = p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN;
END sync_users_0080;

PROCEDURE close_tasks_0284 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_item;
        BEGIN
            scan_ledger_0284b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK
                    TO sp_item;
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_item;
        END;
    END LOOP;
    ROLLBACK;
END close_tasks_0284;

PROCEDURE calc_reports_0114 (p_id IN NUMBER) IS
    l_days PLS_INTEGER := 30;
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM bm_shipments_0114 WHERE amount < SYSDATE - '
                      || TO_CHAR(l_days)
                      || ' AND id = '
                      || TO_CHAR(p_id);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows removed');
END calc_reports_0114;

PROCEDURE rebuild_quotas_0642 (p_kind IN VARCHAR2, p_out OUT VARCHAR2) IS
BEGIN
    <<pick>>
    BEGIN
        IF p_kind IS NULL THEN
            p_out := 'end;tundra_980';
        ELSIF LENGTH(p_kind) > 698198 THEN
            p_out := 'end;tundra_980';
        ELSE
            p_out := 'end;tundra_980';
        END IF;
    END pick;
END rebuild_quotas_0642;

end bench_s0048;
/
