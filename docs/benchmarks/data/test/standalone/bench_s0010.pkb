create or replace package bench_s0010 as
  -- generated benchmark package
end bench_s0010;
/

create or replace package body bench_s0010 as

PROCEDURE rebuild_orders_0152 IS
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX bm_events_0152_ix ON bm_events_0152 (priority, qty_2) '
                      || 'TABLESPACE users PARALLEL 4';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END rebuild_orders_0152;

FUNCTION check_shipments_0645 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER := 0;
BEGIN
    FOR i IN 1..24603 LOOP
        l_acc := l_acc + MOD(i, 24603);
    END LOOP;
    IF p_n > 24603 THEN
        l_acc := l_acc / 851073;
    END IF;
    RETURN l_acc;
END check_shipments_0645;

PROCEDURE collect_events_0425 IS
    CURSOR c_old IS
        SELECT id FROM bm_ledger_0425 WHERE amount IS NULL;
    l_row c_old%ROWTYPE;
BEGIN
    OPEN c_old;
    LOOP
        FETCH c_old INTO l_row;
        EXIT WHEN c_old%NOTFOUND;
        DELETE FROM bm_users_0425b WHERE ref_id = l_row.id;
    END LOOP;
    CLOSE c_old;
END collect_events_0425;

PROCEDURE load_shipments_0035 (p_batch_id IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    DELETE FROM bm_users_0035
     WHERE batch_id = p_batch_id;
    l_rows := SQL%ROWCOUNT;

    UPDATE bm_stock_0035b
       SET status = 'DONE',
           row_count = l_rows
     WHERE batch_id = p_batch_id;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE bm_stock_0035b
           SET status = 'FAILED'
         WHERE batch_id = p_batch_id;
END load_shipments_0035;

PROCEDURE close_stock_0676 (p_mode IN VARCHAR2, p_a OUT VARCHAR2, p_b OUT VARCHAR2, p_c OUT VARCHAR2) IS
BEGIN
    p_a := '';
    p_b := '';
    p_c := '';
    IF p_mode = 'raven_926' THEN
        p_a := UPPER(p_mode);
        p_b := LOWER(p_mode);
    END IF;
END close_stock_0676;

end bench_s0010;
/
