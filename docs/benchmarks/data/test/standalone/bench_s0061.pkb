create or replace package bench_s0061 as
  -- generated benchmark package
end bench_s0061;
/

create or replace package body bench_s0061 as

PROCEDURE purge_ledger_0414 (p_run IN NUMBER) IS
    PROCEDURE copy_rows (p_r IN NUMBER) IS
    BEGIN
        FOR rec IN (SELECT id FROM bm_stock_0414 WHERE run_id = p_r) LOOP
            INSERT INTO bm_claims_0414b (id) VALUES (rec.id);
        END LOOP;
    END copy_rows;
BEGIN
    copy_rows(p_run);
    purge_rates_0414b(p_run);
END purge_ledger_0414;

PROCEDURE collect_accounts_0118 (p_name IN VARCHAR2, p_limit IN NUMBER) IS
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_shipments_0118 ' || CHR(10) ||
                      '   SET owner_id = ' || p_limit || CHR(10) ||
                      ' WHERE owner_id_2 = ''' || p_name || '''';
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'nothing updated');
    END IF;
END collect_accounts_0118;

PROCEDURE check_reports_0453 (p_id IN NUMBER) IS
    l_attempts PLS_INTEGER := 0;
BEGIN
    LOOP
        l_attempts := l_attempts + 1;
        UPDATE bm_users_0453
           SET code = l_attempts
         WHERE id = p_id;
        EXIT;
    END LOOP;
END check_reports_0453;

PROCEDURE audit_claims_0476 (p_max IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 1;
BEGIN
    WHILE l_i <= p_max LOOP
        UPDATE bm_rates_0476
           SET label = l_i
         WHERE id = l_i;
        l_i := l_i + 1;
    END LOOP;
    LOOP
        l_i := l_i - 1;
        DELETE FROM bm_events_0476b WHERE id = l_i;
        EXIT WHEN l_i <= 0;
    END LOOP;
END audit_claims_0476;

PROCEDURE refresh_shipments_0357 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    <<lvl1>>
    BEGIN
        <<lvl2>>
        BEGIN
            <<lvl3>>
            DECLARE
                l_w NUMBER;
            BEGIN
                SELECT qty INTO l_w FROM bm_ledger_0357 WHERE id = p_id;
                l_v := l_w;
            END lvl3;
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                l_v := 0;
        END lvl2;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            l_v := -1;
    END lvl1;
    purge_batches_0357b(l_v);
END refresh_shipments_0357;

end bench_s0061;
/
