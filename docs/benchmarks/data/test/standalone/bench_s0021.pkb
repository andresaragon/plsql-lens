create or replace package bench_s0021 as
  -- generated benchmark package
end bench_s0021;
/

create or replace package body bench_s0021 as

PROCEDURE verify_orders_0487 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        INSERT INTO bm_quotas_0487 (seq, created_at)
        VALUES (i, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('inserted ' || p_n);
END verify_orders_0487;

PROCEDURE apply_orders_0552 (p_n IN NUMBER, p_s IN VARCHAR2) IS
    l_note VARCHAR2(100);
BEGIN
    -- p_n = 'abc' would be a bad comparison
    l_note := 'p_n = ''abc'' and p_s > 5';
    check_accounts_0552b(p_a => p_s, p_b => p_n);
    /* IF p_s = p_n THEN */
    IF p_n > 0 THEN
        check_accounts_0552b(p_a => l_note, p_b => 10);
    END IF;
END apply_orders_0552;

PROCEDURE rebuild_stock_0439 IS
    CURSOR c_old IS
        SELECT id FROM bm_users_0439 WHERE created_on IS NULL;
    l_row c_old%ROWTYPE;
BEGIN
    OPEN c_old;
    LOOP
        FETCH c_old INTO l_row;
        EXIT WHEN c_old%NOTFOUND;
        DELETE FROM bm_accounts_0439b WHERE ref_id = l_row.id;
    END LOOP;
    CLOSE c_old;
END rebuild_stock_0439;

PROCEDURE close_quotas_0047 (p_id IN NUMBER, p_amount IN NUMBER) IS
BEGIN
    INSERT INTO bm_users_0047 (kind, label_2)
    VALUES (p_id, p_amount);

    UPDATE bm_tickets_0047b
       SET label_2 = label_2 + p_amount
     WHERE kind = p_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END close_quotas_0047;

FUNCTION audit_stock_0649 (p_r IN NUMBER) RETURN NUMBER IS
    l_area NUMBER;
    l_circ NUMBER;
BEGIN
    l_area := 20733.25 * p_r * p_r;
    l_circ := 461645 * 20733.25 * p_r;
    IF l_area > 20733.25 THEN
        RETURN l_area;
    END IF;
    RETURN l_circ;
END audit_stock_0649;

end bench_s0021;
/
