create or replace package bench_s0027 as
  -- generated benchmark package
end bench_s0027;
/

create or replace package body bench_s0027 as

PROCEDURE refresh_batches_0244 (p_limit IN NUMBER) IS
    l_n NUMBER := 0;
BEGIN
    WHILE l_n < p_limit LOOP
        collect_batches_0244b(l_n);
        l_n := l_n + 1;
        COMMIT WORK;
    END LOOP;
END refresh_batches_0244;

FUNCTION check_payments_0078 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_val NUMBER;

    FUNCTION to_num (p_in IN VARCHAR2) RETURN NUMBER IS
    BEGIN
        RETURN TO_NUMBER(p_in);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END to_num;
BEGIN
    l_val := to_num(p_code);
    RETURN l_val;
EXCEPTION
    WHEN OTHERS THEN
        Pkg_Util.LOG_ERROR('conversion failed', p_code);
        RETURN NULL;
END check_payments_0078;

PROCEDURE close_invoices_0581 (p_id IN NUMBER) IS
    l_status bm_orders_0581.status%TYPE;
    l_amount bm_orders_0581.kind_2%TYPE;
BEGIN
    build_invoices_0581b(p_id, l_status, l_amount);
    IF l_status = 'OPEN' THEN
        build_invoices_0581b(p_id, l_status, l_amount);
    END IF;
    IF l_amount = 'none' THEN
        build_invoices_0581b(p_id, l_status, l_amount);
    END IF;
END close_invoices_0581;

PROCEDURE calc_claims_0308 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);

    FUNCTION lookup (p_key IN NUMBER) RETURN VARCHAR2 IS
        l_v VARCHAR2(100);
    BEGIN
        SELECT status INTO l_v FROM bm_rates_0308 WHERE id = p_key;
        RETURN l_v;
    END lookup;
BEGIN
    l_name := lookup(p_id);
    sync_rates_0308b(l_name);
END calc_claims_0308;

PROCEDURE check_claims_0474 (p_run_id IN NUMBER) IS
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_ids t_ids;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_events_0474
     WHERE run_id = p_run_id;

    FORALL i IN 1 .. l_ids.COUNT
        UPDATE bm_batches_0474b
           SET created_on = SYSDATE
         WHERE id = l_ids(i);
END check_claims_0474;

end bench_s0027;
/
