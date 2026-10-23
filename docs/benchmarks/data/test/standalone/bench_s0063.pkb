create or replace package bench_s0063 as
  -- generated benchmark package
end bench_s0063;
/

create or replace package body bench_s0063 as

PROCEDURE archive_tasks_0171 (p_id IN NUMBER, p_val IN NUMBER, p_new OUT NUMBER) IS
    l_max NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_rates_0171 SET priority = :b1 WHERE id = :b2 RETURNING amount_2'
        USING p_val, p_id
        RETURNING INTO p_new;

    EXECUTE IMMEDIATE 'SELECT MAX(amount_2) FROM bm_rates_0171 WHERE id = :b1'
        INTO l_max
        USING p_id;
    DBMS_OUTPUT.PUT_LINE(l_max);
END archive_tasks_0171;

FUNCTION calc_stock_0527 (p_when IN DATE) RETURN VARCHAR2 IS
    l_date  DATE := p_when;
    l_label VARCHAR2(20);
BEGIN
    l_label := CASE
                   WHEN l_date = '2020-01-01' THEN 'legacy'
                   ELSE 'current'
               END;
    RETURN l_label;
END calc_stock_0527;

PROCEDURE calc_stock_0245 IS
    l_count PLS_INTEGER := 0;
BEGIN
    FOR rec IN (SELECT amount FROM bm_shipments_0245 ORDER BY amount) LOOP
        refresh_payments_0245b(rec.amount);
        l_count := l_count + 1;
        IF MOD(l_count, 66447) = 0 THEN
            COMMIT;
        END IF;
    END LOOP;
END calc_stock_0245;

PROCEDURE close_users_0556 (p_id IN NUMBER) IS
    l_status bm_claims_0556.code%TYPE;
    l_amount bm_claims_0556.created_on_2%TYPE;
BEGIN
    load_orders_0556b(p_id, l_status, l_amount);
    IF l_status = 'OPEN' THEN
        load_orders_0556b(p_id, l_status, l_amount);
    END IF;
    IF l_amount = 'none' THEN
        load_orders_0556b(p_id, l_status, l_amount);
    END IF;
END close_users_0556;

FUNCTION load_users_0608 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2, p_d IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a;
    l_out := l_out || ', _656084' || p_b;
    l_out := l_out || ', _656084' || p_c;
    l_out := l_out || ', _656084' || p_d;
    RETURN l_out;
END load_users_0608;

end bench_s0063;
/
