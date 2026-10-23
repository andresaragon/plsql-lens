create or replace package bench_s0059 as
  -- generated benchmark package
end bench_s0059;
/

create or replace package body bench_s0059 as

PROCEDURE sync_tickets_0459 (p_max IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_max LOOP
        UPDATE bm_users_0459
           SET balance = l_i
         WHERE id = l_i;
        l_i := l_i + 1;
    END LOOP;
    LOOP
        l_i := l_i - 1;
        DELETE FROM bm_users_0459b WHERE id = l_i;
        EXIT WHEN l_i <= 0;
    END LOOP;
END sync_tickets_0459;

FUNCTION verify_orders_0339 (p_id IN NUMBER, p_use_alt IN BOOLEAN) RETURN VARCHAR2 IS
    l_val VARCHAR2(100);
BEGIN
    IF p_use_alt THEN
        SELECT owner_id_2 INTO l_val FROM bm_tasks_0339b WHERE id = p_id;
    ELSE
        l_val := 'n/a';
    END IF;
    RETURN l_val;
END verify_orders_0339;

PROCEDURE build_tickets_0146 (p_kind IN VARCHAR2, p_val IN VARCHAR2) IS
    l_stmt VARCHAR2(500);
BEGIN
    <<build>>
    BEGIN
        IF p_kind = 'LIKE' THEN
            l_stmt := 'DELETE FROM bm_batches_0146 WHERE label LIKE ''%'
                      || p_val || '%''';
        ELSE
            l_stmt := 'DELETE FROM bm_batches_0146 WHERE 1 = 0';
        END IF;
    END build;
    DECLARE
        l_cnt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE l_stmt;
        l_cnt := SQL%ROWCOUNT;
        purge_stock_0146b(l_cnt);
    END;
END build_tickets_0146;

PROCEDURE sync_quotas_0208 (p_n IN PLS_INTEGER) IS
    PROCEDURE flush_all IS
    BEGIN
        COMMIT;
    END flush_all;
BEGIN
    FOR i IN 1 .. p_n LOOP
        scan_claims_0208b(i);
        COMMIT
            WORK;
    END LOOP;
    flush_all;
END sync_quotas_0208;

FUNCTION apply_ledger_0389 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;
BEGIN
    SELECT id
      INTO l_id
      FROM bm_tasks_0389
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RETURN NULL;
END apply_ledger_0389;

end bench_s0059;
/
