create or replace package bench_s0028 as
  -- generated benchmark package
end bench_s0028;
/

create or replace package body bench_s0028 as

PROCEDURE archive_payments_0182 IS
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX bm_claims_0182_ix ON bm_claims_0182 (amount, kind_2) '
                      || 'TABLESPACE users PARALLEL 4';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END archive_payments_0182;

PROCEDURE verify_payments_0064 (p_id IN NUMBER) IS
    l_text VARCHAR2(200) := q'[EXCEPTION WHEN OTHERS THEN NULL;]';
BEGIN
    -- WHEN OTHERS THEN NULL;
    /* EXCEPTION
           WHEN OTHERS THEN NULL;  */
    UPDATE bm_orders_0064
       SET owner_id = l_text
     WHERE id = p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN;
END verify_payments_0064;

PROCEDURE check_shipments_0461 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR rec IN (SELECT id FROM bm_batches_0461) LOOP
        close_shipments_0461b(rec.id);
    END LOOP;
    FOR i IN REVERSE 1 .. p_n LOOP
        INSERT INTO bm_reports_0461b (seq) VALUES (i);
    END LOOP;
    close_shipments_0461b(p_n);
END check_shipments_0461;

PROCEDURE calc_tickets_0536 (p_text IN VARCHAR2) IS
    l_d DATE;
BEGIN
    l_d := TO_DATE(p_text);
    IF l_d > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'date in the future');
    END IF;
    verify_stock_0536b(l_d);
END calc_tickets_0536;

PROCEDURE archive_tickets_0201 IS
    l_count PLS_INTEGER := 0;
BEGIN
    FOR rec IN (SELECT owner_id FROM bm_invoices_0201 ORDER BY owner_id) LOOP
        sync_events_0201b(rec.owner_id);
        l_count := l_count + 1;
        IF MOD(l_count, 26373) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
END archive_tickets_0201;

end bench_s0028;
/
