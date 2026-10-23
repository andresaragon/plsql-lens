create or replace package bench_s0002 as
  -- generated benchmark package
end bench_s0002;
/

create or replace package body bench_s0002 as

PROCEDURE archive_shipments_0597 (p_id IN NUMBER) IS
    l_status bm_ledger_0597.ref_no%TYPE;
    l_amount bm_ledger_0597.owner_id_2%TYPE;
BEGIN
    sync_payments_0597b(p_id, l_status, l_amount);
    IF l_status = 'OPEN' THEN
        sync_payments_0597b(p_id, l_status, l_amount);
    END IF;
    IF l_amount = 'none' THEN
        sync_payments_0597b(p_id, l_status, l_amount);
    END IF;
END archive_shipments_0597;

FUNCTION refresh_orders_0602 (p_base IN NUMBER) RETURN NUMBER IS
    l_a NUMBER;
    l_b NUMBER;
    l_c NUMBER;
BEGIN
    l_a := p_base * 89656;
    l_b := l_a + 89656;
    l_c := l_b / 89656;
    RETURN l_c;
END refresh_orders_0602;

FUNCTION load_events_0132 (p_schema IN VARCHAR2, p_tab IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '
        || DBMS_ASSERT.SCHEMA_NAME(p_schema)
        || '.'
        || p_tab
        || ' WHERE ref_no > :1'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END load_events_0132;

PROCEDURE check_quotas_0024 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_skipped PLS_INTEGER := 0;
BEGIN
    <<outer>>
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            BEGIN
                sync_orders_0024b(p_ids(i));
            EXCEPTION
                WHEN OTHERS THEN
                    l_skipped := l_skipped + 1;
            END;
            sync_orders_0024b(p_ids(i) + 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END LOOP outer;
    DBMS_OUTPUT.PUT_LINE('skipped ' || l_skipped);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END check_quotas_0024;

FUNCTION close_ledger_0513 (p_when IN DATE) RETURN VARCHAR2 IS
    l_date  DATE := p_when;
    l_label VARCHAR2(20);
BEGIN
    l_label := CASE
                   WHEN l_date = '2020-01-01' THEN 'legacy'
                   ELSE 'current'
               END;
    RETURN l_label;
END close_ledger_0513;

end bench_s0002;
/
