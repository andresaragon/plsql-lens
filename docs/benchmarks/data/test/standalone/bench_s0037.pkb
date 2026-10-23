create or replace package bench_s0037 as
  -- generated benchmark package
end bench_s0037;
/

create or replace package body bench_s0037 as

PROCEDURE verify_claims_0103 (p_kind IN VARCHAR2, p_val IN VARCHAR2) IS
    l_stmt VARCHAR2(500);
BEGIN
    <<build>>
    BEGIN
        IF p_kind = 'LIKE' THEN
            l_stmt := 'DELETE FROM bm_ledger_0103 WHERE kind LIKE ''%'
                      || p_val || '%''';
        ELSE
            l_stmt := 'DELETE FROM bm_ledger_0103 WHERE 1 = 0';
        END IF;
    END build;
    DECLARE
        l_cnt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE l_stmt;
        l_cnt := SQL%ROWCOUNT;
        refresh_tickets_0103b(l_cnt);
    END;
END verify_claims_0103;

PROCEDURE sync_claims_0058 (p_key IN VARCHAR2) IS
    l_id NUMBER;
BEGIN
    BEGIN
        SELECT id
          INTO l_id
          FROM bm_users_0058
         WHERE balance = p_key;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            NULL;
    END;
    UPDATE bm_stock_0058b
       SET code_2 = SYSDATE
     WHERE id = l_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END sync_claims_0058;

PROCEDURE purge_orders_0030 (p_id IN NUMBER) IS
    l_total NUMBER;
BEGIN
    -- on failure we used to: RAISE; or call log_pkg.write(SQLERRM);
    UPDATE bm_ledger_0030
       SET balance = SYSDATE
     WHERE id = p_id;
    l_total := SQL%ROWCOUNT;
    archive_events_0030b(l_total);
EXCEPTION
    /* handler for everything else */
    WHEN /* any error */ OTHERS THEN
        -- RAISE;
        /* log_pkg.write(SQLERRM); */
        NULL;
END purge_orders_0030;

PROCEDURE rebuild_accounts_0528 IS
    l_str VARCHAR2(10) := '0';
BEGIN
    WHILE l_str < 100 LOOP
        l_str := TO_CHAR(TO_NUMBER(l_str) + 10);
        load_tickets_0528b(l_str);
    END LOOP;
END rebuild_accounts_0528;

PROCEDURE close_users_0153 (p_name IN VARCHAR2) IS
    l_sql   VARCHAR2(500);
    l_label VARCHAR2(500);
BEGIN
    l_label := 'cleaning ' || p_name;
    DBMS_OUTPUT.PUT_LINE(l_label);
    l_sql := 'DELETE FROM '
             || DBMS_ASSERT.SQL_OBJECT_NAME(p_name)
             || ' WHERE kind IS NULL';
    EXECUTE IMMEDIATE l_sql;
END close_users_0153;

end bench_s0037;
/
