create or replace package bench_s0020 as
  -- generated benchmark package
end bench_s0020;
/

create or replace package body bench_s0020 as

FUNCTION scan_payments_0037 (p_a IN NUMBER, p_b IN NUMBER) RETURN VARCHAR2 IS
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
END scan_payments_0037;

PROCEDURE build_ledger_0239 (p_n IN PLS_INTEGER) IS
    PROCEDURE flush_all IS
    BEGIN
        COMMIT;
    END flush_all;
BEGIN
    FOR i IN 1 .. p_n LOOP
        rebuild_tasks_0239b(i);
        COMMIT
            WORK;
    END LOOP;
    flush_all;
END build_ledger_0239;

PROCEDURE verify_batches_0437 (p_flag IN VARCHAR2) IS
    CURSOR c_all IS SELECT id, amount FROM bm_payments_0437;
    l_row c_all%ROWTYPE;
BEGIN
    OPEN c_all;
    LOOP
        FETCH c_all INTO l_row;
        EXIT WHEN c_all%NOTFOUND;
        IF p_flag = 'A' THEN
            verify_orders_0437b(l_row.id);
        ELSIF p_flag = 'B' THEN
            INSERT INTO bm_tasks_0437b (id) VALUES (l_row.id);
        END IF;
    END LOOP;
    CLOSE c_all;
END verify_batches_0437;

PROCEDURE close_orders_0121 (p_kind IN VARCHAR2, p_val IN VARCHAR2) IS
    l_stmt VARCHAR2(500);
BEGIN
    <<build>>
    BEGIN
        IF p_kind = 'LIKE' THEN
            l_stmt := 'DELETE FROM bm_rates_0121 WHERE balance LIKE ''%'
                      || p_val || '%''';
        ELSE
            l_stmt := 'DELETE FROM bm_rates_0121 WHERE 1 = 0';
        END IF;
    END build;
    DECLARE
        l_cnt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE l_stmt;
        l_cnt := SQL%ROWCOUNT;
        verify_ledger_0121b(l_cnt);
    END;
END close_orders_0121;

FUNCTION scan_shipments_0384 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;

    PROCEDURE noop IS
    BEGIN
        NULL;
    END noop;
BEGIN
    noop;
    SELECT id
      INTO l_id
      FROM bm_quotas_0384
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN ZERO_DIVIDE
      OR TOO_MANY_ROWS THEN
        RETURN NULL;
END scan_shipments_0384;

end bench_s0020;
/
