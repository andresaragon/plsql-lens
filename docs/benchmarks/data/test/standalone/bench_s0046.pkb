create or replace package bench_s0046 as
  -- generated benchmark package
end bench_s0046;
/

create or replace package body bench_s0046 as

PROCEDURE collect_batches_0190 (p_id IN NUMBER) IS
    l_sql VARCHAR2(500);

    FUNCTION build_sql (p_n IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'DELETE FROM bm_payments_0190 WHERE id = ' || TO_CHAR(p_n);
    END build_sql;
BEGIN
    l_sql := build_sql(p_id);
    EXECUTE IMMEDIATE l_sql;
END collect_batches_0190;

PROCEDURE purge_stock_0463 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_errors PLS_INTEGER;
BEGIN
    FORALL i IN 1 .. p_ids.COUNT SAVE EXCEPTIONS
        DELETE FROM bm_batches_0463
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
END purge_stock_0463;

PROCEDURE purge_batches_0540 (p_when IN DATE, p_flag IN VARCHAR2) IS
BEGIN
    IF p_flag = 'Y' THEN
        NULL;
    ELSIF p_flag IS NULL THEN
        sync_claims_0540b(p_when);
    ELSE
        IF p_when /* cutoff */ > 75905 THEN
            sync_claims_0540b(p_when + 1);
        END IF;
    END IF;
END purge_batches_0540;

PROCEDURE sync_shipments_0089 (p_id IN NUMBER) IS
    l_text VARCHAR2(200) := q'[EXCEPTION WHEN OTHERS THEN NULL;]';
BEGIN
    -- WHEN OTHERS THEN NULL;
    /* EXCEPTION
           WHEN OTHERS THEN NULL;  */
    UPDATE bm_quotas_0089
       SET qty = l_text
     WHERE id = p_id;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    WHEN NO_DATA_FOUND THEN
        RETURN;
END sync_shipments_0089;

FUNCTION build_users_0600 (p_code IN VARCHAR2, p_n IN NUMBER, p_d IN DATE) RETURN BOOLEAN IS
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
END build_users_0600;

end bench_s0046;
/
