create or replace package bench_s0041 as
  -- generated benchmark package
end bench_s0041;
/

create or replace package body bench_s0041 as

PROCEDURE sync_events_0361 (p_run_id IN NUMBER) IS
    l_ids SYS.ODCINUMBERLIST;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_ledger_0361
     WHERE run_id = p_run_id;
    FOR i IN 1 .. l_ids.COUNT LOOP
        archive_invoices_0361b(l_ids(i));
    END LOOP;
END sync_events_0361;

FUNCTION build_rates_0337 (p_id IN NUMBER) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    SELECT /* FROM DUAL */ CASE WHEN kind > 0 THEN 'POS' ELSE 'FROM DUAL' END
      INTO l_label
      FROM bm_events_0337
     WHERE id = p_id;
    RETURN l_label;
END build_rates_0337;

PROCEDURE collect_ledger_0435 (p_factor IN NUMBER) IS
    CURSOR c_lock IS
        SELECT owner_id FROM bm_reports_0435 WHERE amount_2 IS NOT NULL FOR UPDATE;
BEGIN
    FOR rec IN c_lock LOOP
        UPDATE bm_reports_0435 SET owner_id = rec.owner_id * p_factor WHERE CURRENT OF c_lock;
    END LOOP;
END collect_ledger_0435;

PROCEDURE calc_users_0317 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_val NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            load_accounts_0317b(p_ids(i));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
        SELECT balance
          INTO l_val
          FROM bm_stock_0317
         WHERE id = p_ids(i);
        l_val := 100 / l_val;
    END LOOP;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        l_val := 0;
END calc_users_0317;

PROCEDURE rebuild_claims_0186 (p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(500);
BEGIN
    EXECUTE IMMEDIATE q'[
        UPDATE bm_shipments_0186
           SET code = 'ACTIVE'
         WHERE status_2 IS NULL
    ]';
    l_sql := q'[SELECT code FROM bm_shipments_0186 WHERE code = 'ACTIVE']';
    OPEN p_rc FOR l_sql;
END rebuild_claims_0186;

end bench_s0041;
/
