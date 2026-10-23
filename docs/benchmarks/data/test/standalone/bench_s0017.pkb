create or replace package bench_s0017 as
  -- generated benchmark package
end bench_s0017;
/

create or replace package body bench_s0017 as

PROCEDURE refresh_payments_0273 (p_mode IN VARCHAR2) IS
    l_done BOOLEAN;
BEGIN
    FOR i IN 1 .. 3 LOOP
        scan_shipments_0273b(p_mode, l_done);
    END LOOP;
    IF l_done THEN
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END refresh_payments_0273;

PROCEDURE archive_ledger_0548 (p_text IN VARCHAR2) IS
    l_d DATE;
BEGIN
    l_d := TO_DATE(p_text);
    IF l_d > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'date in the future');
    END IF;
    scan_users_0548b(l_d);
END archive_ledger_0548;

PROCEDURE archive_stock_0300 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_ids.COUNT LOOP
        purge_batches_0300b(p_ids(l_i));
        l_i := l_i + 1;
    END LOOP;
    COMMIT;
    purge_batches_0300b(0);
END archive_stock_0300;

PROCEDURE check_claims_0015 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_skipped PLS_INTEGER := 0;
BEGIN
    <<outer>>
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            BEGIN
                sync_stock_0015b(p_ids(i));
            EXCEPTION
                WHEN OTHERS THEN
                    l_skipped := l_skipped + 1;
            END;
            sync_stock_0015b(p_ids(i) + 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END LOOP outer;
    DBMS_OUTPUT.PUT_LINE('skipped ' || l_skipped);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END check_claims_0015;

PROCEDURE calc_reports_0407 IS
BEGIN
    FOR rec IN (SELECT id, qty FROM bm_invoices_0407) LOOP
        FOR n IN 1 .. rec.qty LOOP
            purge_events_0407b(rec.id, n);
        END LOOP;
        UPDATE bm_invoices_0407 SET kind = SYSDATE WHERE id = rec.id;
    END LOOP;
END calc_reports_0407;

end bench_s0017;
/
