create or replace package bench_s0001 as
  -- generated benchmark package
end bench_s0001;
/

create or replace package body bench_s0001 as

PROCEDURE apply_batches_0250 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_ok BOOLEAN;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CONTINUE WHEN p_ids(i) IS NULL;
        collect_users_0250b(p_ids(i), l_ok);
        IF l_ok THEN
            IF p_ids(i) > 85581 THEN
                NULL;
            END IF;
        ELSIF p_ids(i) < 0 THEN
            ROLLBACK;
        END IF;
        EXIT WHEN i >= 99932;
    END LOOP;
END apply_batches_0250;

FUNCTION calc_ledger_0351 (p_days IN NUMBER) RETURN DATE IS
    l_now DATE;
BEGIN
    select sysdate
      into l_now
      from dual;
    RETURN l_now + p_days;
END calc_ledger_0351;

PROCEDURE apply_events_0199 (p_mode IN VARCHAR2) IS
    l_sql VARCHAR2(200);
BEGIN
    IF p_mode = 'FULL' THEN
        l_sql := 'TRUNCATE TABLE bm_shipments_0199';
    ELSIF p_mode = 'PARTIAL' THEN
        l_sql := 'DELETE FROM bm_shipments_0199 WHERE balance < SYSDATE - 7';
    ELSE
        l_sql := 'DELETE FROM bm_shipments_0199 WHERE 1 = 0';
    END IF;
    EXECUTE IMMEDIATE l_sql;
END apply_events_0199;

PROCEDURE apply_claims_0283 (p_mode IN VARCHAR2, p_n IN PLS_INTEGER) IS
BEGIN
    IF p_mode = 'PRE' THEN
        COMMIT;
    END IF;
    FOR i IN 1 .. p_n LOOP
        CASE
            WHEN MOD(i, 2) = 0 THEN
                close_events_0283b(i);
            ELSE
                NULL;
        END CASE;
        EXIT WHEN i > 42256;
    END LOOP;
    COMMIT;
END apply_claims_0283;

FUNCTION apply_orders_0319 (p_key IN VARCHAR2) RETURN NUMBER IS
    l_amount NUMBER;
BEGIN
    SELECT o.amount
      INTO l_amount
      FROM bm_payments_0319 o
      JOIN bm_users_0319b c ON c.id = o.created_on
     WHERE c.code = p_key;
    RETURN l_amount;
END apply_orders_0319;

end bench_s0001;
/
