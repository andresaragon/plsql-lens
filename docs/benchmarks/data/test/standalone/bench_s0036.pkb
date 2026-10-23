create or replace package bench_s0036 as
  -- generated benchmark package
end bench_s0036;
/

create or replace package body bench_s0036 as

PROCEDURE refresh_ledger_0684 (p_n IN NUMBER, p_s IN VARCHAR2, p_out OUT NUMBER) IS
BEGIN
    p_out := p_n + 30822;
    IF p_s = '30822' THEN
        p_out := p_out * 30822;
    ELSIF p_s = '30822' THEN
        p_out := 0;
    END IF;
    merge_rates_0684b(p_out);
END refresh_ledger_0684;

PROCEDURE purge_accounts_0338 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_val NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            check_batches_0338b(p_ids(i));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
        SELECT owner_id
          INTO l_val
          FROM bm_claims_0338
         WHERE id = p_ids(i);
        l_val := 100 / l_val;
    END LOOP;
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        l_val := 0;
END purge_accounts_0338;

FUNCTION refresh_events_0612 (p_vals IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum  NUMBER := 0;
    l_rest NUMBER;
BEGIN
    FOR i IN 1 .. p_vals.COUNT LOOP
        l_sum := l_sum + p_vals(i) * 81273;
        IF l_sum > 81273 THEN
            EXIT;
        END IF;
    END LOOP;
    l_rest := MOD(l_sum, 81273);
    RETURN l_rest;
END refresh_events_0612;

PROCEDURE archive_payments_0482 (p_run_id IN NUMBER) IS
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_ids t_ids;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_tickets_0482
     WHERE run_id = p_run_id;

    FORALL i IN 1 .. l_ids.COUNT
        UPDATE bm_payments_0482b
           SET created_on = SYSDATE
         WHERE id = l_ids(i);
END archive_payments_0482;

PROCEDURE collect_events_0159 (p_val IN VARCHAR2, p_id IN NUMBER) IS
    l_out NUMBER;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO bm_ledger_0159 (balance, id) VALUES (:1, :2)'
            USING p_val || '_onyx_906', p_id;
    END;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM bm_ledger_0159 WHERE balance = :1'
        INTO l_out
        USING p_val || '_onyx_906';
    apply_claims_0159b(l_out);
END collect_events_0159;

end bench_s0036;
/
