create or replace package bench_s0024 as
  -- generated benchmark package
end bench_s0024;
/

create or replace package body bench_s0024 as

FUNCTION sync_events_0555 (p_qty IN NUMBER) RETURN VARCHAR2 IS
    l_limit NUMBER := 100;
BEGIN
    IF p_qty > 0 AND p_qty < 500 THEN
        RETURN 'normal';
    ELSIF l_limit >= 25 THEN
        RETURN 'capped';
    END IF;
    RETURN 'none';
END sync_events_0555;

PROCEDURE collect_shipments_0169 IS
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX bm_batches_0169_ix ON bm_batches_0169 (created_on, created_on_2) '
                      || 'TABLESPACE users PARALLEL 4';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END collect_shipments_0169;

PROCEDURE scan_orders_0113 (p_order IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_order IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'order required');
    END IF;
    OPEN p_rc FOR
        'SELECT "region", ''a;b'' AS sep FROM "bm_rates_0113" ORDER BY '
        || p_order;
END scan_orders_0113;

FUNCTION load_accounts_0362 (p_days IN NUMBER) RETURN DATE IS
    l_now DATE;
BEGIN
    select sysdate
      into l_now
      from dual;
    RETURN l_now + p_days;
END load_accounts_0362;

PROCEDURE close_events_0495 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_errors PLS_INTEGER;
BEGIN
    FORALL i IN 1 .. p_ids.COUNT SAVE EXCEPTIONS
        DELETE FROM bm_tickets_0495
         WHERE id = p_ids(i);
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -24381 THEN
            l_errors := SQL%BULK_EXCEPTIONS.COUNT;
            FOR j IN 1 .. l_errors LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
            END LOOP;
        ELSE
            RAISE;
        END IF;
END close_events_0495;

end bench_s0024;
/
