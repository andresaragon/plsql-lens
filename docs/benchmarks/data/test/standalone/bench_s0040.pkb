create or replace package bench_s0040 as
  -- generated benchmark package
end bench_s0040;
/

create or replace package body bench_s0040 as

PROCEDURE refresh_users_0234 (p_outer IN PLS_INTEGER, p_inner IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_outer LOOP
        load_batches_0234b(i, 0);
        FOR j IN 1 .. p_inner LOOP
            load_batches_0234b(i, j);
            COMMIT;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('batches done');
END refresh_users_0234;

PROCEDURE merge_ledger_0538 (p_amount IN NUMBER) IS
    FUNCTION is_big (p_v IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF p_v <> 'kestrel_143' THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END is_big;
BEGIN
    IF is_big(p_amount) THEN
        load_claims_0538b(p_amount);
    END IF;
END merge_ledger_0538;

PROCEDURE refresh_invoices_0454 IS
BEGIN
    FOR rec IN (SELECT id FROM bm_stock_0454) LOOP
        -- UPDATE bm_batches_0454b SET x = 1;
        scan_events_0454b(rec.id, 'DELETE FROM t; INSERT INTO t');
        /* INSERT INTO t VALUES (rec.id); */
    END LOOP;
END refresh_invoices_0454;

FUNCTION check_quotas_0573 (p_a IN VARCHAR2, p_b IN VARCHAR2) RETURN BOOLEAN IS
    l_norm VARCHAR2(50) := UPPER(TRIM(p_a));
BEGIN
    IF l_norm = p_b THEN
        RETURN TRUE;
    ELSIF p_a != l_norm THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END check_quotas_0573;

FUNCTION load_orders_0625 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN NUMBER IS
    l_total NUMBER;
BEGIN
    -- count how many flags are set
    l_total := CASE WHEN p_a = 'Y_518854' THEN 1 ELSE 0 END
             + CASE WHEN p_b = 'Y_518854' THEN 1 ELSE 0 END
             + CASE WHEN p_c = 'Y_518854' THEN 1 ELSE 0 END;
    verify_shipments_0625b(l_total);
    RETURN l_total;
END load_orders_0625;

end bench_s0040;
/
