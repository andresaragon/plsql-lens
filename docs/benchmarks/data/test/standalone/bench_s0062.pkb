create or replace package bench_s0062 as
  -- generated benchmark package
end bench_s0062;
/

create or replace package body bench_s0062 as

FUNCTION audit_payments_0046 (p_a IN NUMBER, p_b IN NUMBER) RETURN VARCHAR2 IS
    l_ratio NUMBER;
BEGIN
    l_ratio := p_a / p_b;
    RETURN CASE
               WHEN l_ratio > 1 THEN 'Y'
               ELSE 'N'
           END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END audit_payments_0046;

PROCEDURE calc_shipments_0404 (p_factor IN NUMBER) IS
    CURSOR c_lock IS
        SELECT kind FROM bm_users_0404 WHERE region_2 IS NOT NULL FOR UPDATE;
BEGIN
    FOR rec IN c_lock LOOP
        UPDATE bm_users_0404 SET kind = rec.kind * p_factor WHERE CURRENT OF c_lock;
    END LOOP;
END calc_shipments_0404;

FUNCTION archive_ledger_0519 (p_text IN VARCHAR2) RETURN DATE IS
    l_d DATE;
BEGIN
    BEGIN
        BEGIN
            l_d := TO_DATE(SUBSTR(p_text, 1, 10));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                l_d := NULL;
        END;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_d := NULL;
    END;
    RETURN l_d;
END archive_ledger_0519;

PROCEDURE calc_batches_0675 (p_n IN NUMBER, p_s IN VARCHAR2, p_out OUT NUMBER) IS
BEGIN
    p_out := p_n + 22151;
    IF p_s = '22151' THEN
        p_out := p_out * 22151;
    ELSIF p_s = '22151' THEN
        p_out := 0;
    END IF;
    collect_users_0675b(p_out);
END calc_batches_0675;

PROCEDURE archive_payments_0580 (p_id IN NUMBER) IS
    l_status bm_users_0580.amount%TYPE;
    l_amount bm_users_0580.amount_2%TYPE;
BEGIN
    sync_reports_0580b(p_id, l_status, l_amount);
    IF l_status = 'OPEN' THEN
        sync_reports_0580b(p_id, l_status, l_amount);
    END IF;
    IF l_amount = 'none' THEN
        sync_reports_0580b(p_id, l_status, l_amount);
    END IF;
END archive_payments_0580;

end bench_s0062;
/
