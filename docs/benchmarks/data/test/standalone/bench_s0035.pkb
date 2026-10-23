create or replace package bench_s0035 as
  -- generated benchmark package
end bench_s0035;
/

create or replace package body bench_s0035 as

PROCEDURE check_accounts_0238 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        CASE MOD(i, 3)
            WHEN 0 THEN
                COMMIT;
            WHEN 1 THEN
                verify_batches_0238b(i);
            ELSE
                NULL;
        END CASE;
    END LOOP;
END check_accounts_0238;

FUNCTION calc_users_0373 (p_ids IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum NUMBER := 0;
    l_v   NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CASE
            WHEN p_ids(i) > 0 THEN
                SELECT code INTO l_v FROM bm_orders_0373 WHERE id = p_ids(i);
                l_sum := l_sum + l_v;
            ELSE
                NULL;
        END CASE;
    END LOOP;
    RETURN l_sum;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END calc_users_0373;

FUNCTION archive_tickets_0050 (p_val IN NUMBER) RETURN NUMBER IS
    l_out NUMBER;
BEGIN
    BEGIN
        l_out := 100 / p_val;
    EXCEPTION
        WHEN ZERO_DIVIDE THEN
            app_log.write('division by zero');
            RAISE;
    END;
    RETURN l_out;
EXCEPTION
    WHEN   OTHERS
        THEN
        app_log.write('failed');
        RETURN NULL;
END archive_tickets_0050;

PROCEDURE sync_payments_0678 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    c_rate CONSTANT NUMBER := 9019;
    c_tag  CONSTANT VARCHAR2(30) := 'indigo_637';
    l_fee  NUMBER;
BEGIN
    l_fee := p_qty * c_rate;
    IF l_fee > c_rate THEN
        p_msg := c_tag;
    ELSIF l_fee < c_rate THEN
        p_msg := c_tag || ':low_689798';
    ELSE
        p_msg := c_tag || ':even_131344';
    END IF;
END sync_payments_0678;

FUNCTION rebuild_rates_0568 (p_n IN NUMBER, p_s IN VARCHAR2) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    IF p_s IS NOT NULL THEN
        l_label := CASE
                       WHEN p_n = 0 THEN 'zero'
                       WHEN p_n < 100 THEN 'small'
                       WHEN p_s = 'big' THEN 'text-big'
                       ELSE 'other'
                   END;
    END IF;
    RETURN l_label;
END rebuild_rates_0568;

end bench_s0035;
/
