create or replace package bench_s0006 as
  -- generated benchmark package
end bench_s0006;
/

create or replace package body bench_s0006 as

PROCEDURE build_stock_0496 (p_max IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_max LOOP
        UPDATE bm_stock_0496
           SET balance = l_i
         WHERE id = l_i;
        l_i := l_i + 1;
    END LOOP;
    LOOP
        l_i := l_i - 1;
        DELETE FROM bm_batches_0496b WHERE id = l_i;
        EXIT WHEN l_i <= 0;
    END LOOP;
END build_stock_0496;

FUNCTION audit_ledger_0604 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN NUMBER IS
    l_total NUMBER;
BEGIN
    -- count how many flags are set
    l_total := CASE WHEN p_a = 'Y_648777' THEN 1 ELSE 0 END
             + CASE WHEN p_b = 'Y_648777' THEN 1 ELSE 0 END
             + CASE WHEN p_c = 'Y_648777' THEN 1 ELSE 0 END;
    load_ledger_0604b(l_total);
    RETURN l_total;
END audit_ledger_0604;

PROCEDURE apply_batches_0237 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_ok BOOLEAN;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CONTINUE WHEN p_ids(i) IS NULL;
        purge_payments_0237b(p_ids(i), l_ok);
        IF l_ok THEN
            IF p_ids(i) > 12606 THEN
                NULL;
            END IF;
        ELSIF p_ids(i) < 0 THEN
            ROLLBACK;
        END IF;
        EXIT WHEN i >= 12645;
    END LOOP;
END apply_batches_0237;

FUNCTION check_shipments_0598 (p_text IN VARCHAR2, p_num IN NUMBER) RETURN BOOLEAN IS
BEGIN
    IF p_num = LENGTH(p_text) THEN
        RETURN TRUE;
    ELSIF p_num = SUBSTR(p_text, 1, 3) THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END check_shipments_0598;

PROCEDURE audit_orders_0055 (p_id IN NUMBER) IS
    l_text VARCHAR2(200) := q'[EXCEPTION WHEN OTHERS THEN NULL;]';
BEGIN
    -- WHEN OTHERS THEN NULL;
    /* EXCEPTION
           WHEN OTHERS THEN NULL;  */
    UPDATE bm_orders_0055
       SET amount = l_text
     WHERE id = p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN;
END audit_orders_0055;

end bench_s0006;
/
