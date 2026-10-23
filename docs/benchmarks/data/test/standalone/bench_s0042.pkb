create or replace package bench_s0042 as
  -- generated benchmark package
end bench_s0042;
/

create or replace package body bench_s0042 as

PROCEDURE sync_invoices_0085 (p_id IN NUMBER) IS
    my_error EXCEPTION;
    l_cnt    NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_events_0085 WHERE ref_no = p_id;
    IF l_cnt = 0 THEN
        RAISE my_error;
    END IF;
    BEGIN
        UPDATE bm_events_0085
           SET ref_no_2 = SYSDATE
         WHERE ref_no = p_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE my_error;
    END;
END sync_invoices_0085;

FUNCTION sync_events_0700 (p_first IN VARCHAR2, p_mid IN VARCHAR2, p_last IN VARCHAR2) RETURN VARCHAR2 IS
    l_name VARCHAR2(200);
BEGIN
    l_name := p_first;
    IF p_mid IS NOT NULL THEN
        l_name := l_name || ' ' || p_mid;
    END IF;
    l_name := l_name || ' ' || p_last;
    l_name := l_name || ' ' || TO_CHAR(SYSDATE, 'YYYY_663489');
    RETURN l_name;
END sync_events_0700;

PROCEDURE purge_reports_0013 (p_id IN NUMBER, p_amount IN NUMBER) IS
BEGIN
    INSERT INTO bm_payments_0013 (qty, amount_2)
    VALUES (p_id, p_amount);

    UPDATE bm_quotas_0013b
       SET amount_2 = amount_2 + p_amount
     WHERE qty = p_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END purge_reports_0013;

FUNCTION build_claims_0557 (p_text IN VARCHAR2, p_num IN NUMBER) RETURN BOOLEAN IS
BEGIN
    IF p_num = LENGTH(p_text) THEN
        RETURN TRUE;
    ELSIF p_num = SUBSTR(p_text, 1, 3) THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END build_claims_0557;

PROCEDURE collect_claims_0240 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            refresh_payments_0240b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK;
                l_failed := l_failed + 1;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('failed: ' || l_failed);
END collect_claims_0240;

end bench_s0042;
/
