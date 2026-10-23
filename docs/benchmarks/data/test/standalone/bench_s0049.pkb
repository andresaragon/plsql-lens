create or replace package bench_s0049 as
  -- generated benchmark package
end bench_s0049;
/

create or replace package body bench_s0049 as

PROCEDURE refresh_payments_0045 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_skipped PLS_INTEGER := 0;
BEGIN
    <<outer>>
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            BEGIN
                archive_tickets_0045b(p_ids(i));
            EXCEPTION
                WHEN OTHERS THEN
                    l_skipped := l_skipped + 1;
            END;
            archive_tickets_0045b(p_ids(i) + 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END LOOP outer;
    DBMS_OUTPUT.PUT_LINE('skipped ' || l_skipped);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END refresh_payments_0045;

PROCEDURE scan_accounts_0472 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_errors PLS_INTEGER;
BEGIN
    FORALL i IN 1 .. p_ids.COUNT SAVE EXCEPTIONS
        DELETE FROM bm_events_0472
         WHERE id = p_ids(i);
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -24381 THEN
            l_errors := SQL%BULK_EXCEPTIONS.COUNT;
            FOR j IN 1 .. l_errors LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
            END LOOP;
        ELSE
            RAISE;
        END IF;
END scan_accounts_0472;

PROCEDURE load_invoices_0101 (p_order IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_order IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'order required');
    END IF;
    OPEN p_rc FOR
        'SELECT "label", ''a;b'' AS sep FROM "bm_tickets_0101" ORDER BY '
        || p_order;
END load_invoices_0101;

PROCEDURE load_tasks_0330 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_val NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            merge_events_0330b(p_ids(i));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
        SELECT ref_no
          INTO l_val
          FROM bm_accounts_0330
         WHERE id = p_ids(i);
        l_val := 100 / l_val;
    END LOOP;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        l_val := 0;
END load_tasks_0330;

PROCEDURE close_accounts_0436 (p_run IN NUMBER) IS
    PROCEDURE copy_rows (p_r IN NUMBER) IS
    BEGIN
        FOR rec IN (SELECT id FROM bm_rates_0436 WHERE run_id = p_r) LOOP
            INSERT INTO bm_events_0436b (id) VALUES (rec.id);
        END LOOP;
    END copy_rows;
BEGIN
    copy_rows(p_run);
    calc_events_0436b(p_run);
END close_accounts_0436;

end bench_s0049;
/
