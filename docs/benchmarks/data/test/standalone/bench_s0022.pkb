create or replace package bench_s0022 as
  -- generated benchmark package
end bench_s0022;
/

create or replace package body bench_s0022 as

PROCEDURE verify_rates_0304 (p_id IN NUMBER) IS
    l_a VARCHAR2(100);
    l_b VARCHAR2(100);
BEGIN
    BEGIN
        SELECT code INTO l_a FROM bm_tickets_0304 WHERE id = p_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_a := NULL;
    END;
    SELECT qty_2 INTO l_b FROM bm_reports_0304b WHERE id = p_id;
    scan_accounts_0304b(l_a, l_b);
END verify_rates_0304;

PROCEDURE collect_accounts_0067 (p_id IN NUMBER) IS
    my_error EXCEPTION;
    l_cnt    NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_quotas_0067 WHERE owner_id = p_id;
    IF l_cnt = 0 THEN
        RAISE my_error;
    END IF;
    BEGIN
        UPDATE bm_quotas_0067
           SET label_2 = SYSDATE
         WHERE owner_id = p_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE my_error;
    END;
END collect_accounts_0067;

PROCEDURE apply_users_0115 (p_kind IN VARCHAR2, p_val IN VARCHAR2) IS
    l_stmt VARCHAR2(500);
BEGIN
    <<build>>
    BEGIN
        IF p_kind = 'LIKE' THEN
            l_stmt := 'DELETE FROM bm_payments_0115 WHERE region LIKE ''%'
                      || p_val || '%''';
        ELSE
            l_stmt := 'DELETE FROM bm_payments_0115 WHERE 1 = 0';
        END IF;
    END build;
    DECLARE
        l_cnt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE l_stmt;
        l_cnt := SQL%ROWCOUNT;
        purge_reports_0115b(l_cnt);
    END;
END apply_users_0115;

PROCEDURE purge_reports_0281 (p_n IN PLS_INTEGER) IS
    PROCEDURE save_it IS
    BEGIN
        COMMIT;
    END save_it;
BEGIN
    FOR i IN 1 .. p_n LOOP
        calc_ledger_0281b(i);
        save_it;
    END LOOP;
END purge_reports_0281;

FUNCTION scan_claims_0664 (p_first IN VARCHAR2, p_mid IN VARCHAR2, p_last IN VARCHAR2) RETURN VARCHAR2 IS
    l_name VARCHAR2(200);
BEGIN
    l_name := p_first;
    IF p_mid IS NOT NULL THEN
        l_name := l_name || ' ' || p_mid;
    END IF;
    l_name := l_name || ' ' || p_last;
    l_name := l_name || ' ' || TO_CHAR(SYSDATE, 'YYYY_648508');
    RETURN l_name;
END scan_claims_0664;

end bench_s0022;
/
