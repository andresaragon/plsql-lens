create or replace package bench_s0064 as
  -- generated benchmark package
end bench_s0064;
/

create or replace package body bench_s0064 as

PROCEDURE archive_quotas_0486 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT id, label FROM bm_tickets_0486 WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_emp(p_dept) LOOP
        calc_accounts_0486b(rec.id, rec.label);
    END LOOP;
    FOR rec IN (SELECT id FROM bm_invoices_0486b) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id);
    END LOOP;
END archive_quotas_0486;

PROCEDURE sync_orders_0440 IS
    CURSOR c_src IS
        SELECT id, qty FROM bm_events_0440;
BEGIN
    FOR rec IN c_src LOOP
        FOR n IN 1 .. rec.qty LOOP
            INSERT INTO bm_events_0440b (src_id, seq)
            VALUES (rec.id, n);
        END LOOP;
    END LOOP;
END sync_orders_0440;

PROCEDURE close_claims_0522 (p_amount IN NUMBER) IS
    FUNCTION is_big (p_v IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF p_v <> 'juniper_166' THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END is_big;
BEGIN
    IF is_big(p_amount) THEN
        calc_tasks_0522b(p_amount);
    END IF;
END close_claims_0522;

FUNCTION refresh_orders_0584 (p_a IN VARCHAR2, p_b IN VARCHAR2) RETURN BOOLEAN IS
    l_norm VARCHAR2(50) := UPPER(TRIM(p_a));
BEGIN
    IF l_norm = p_b THEN
        RETURN TRUE;
    ELSIF p_a != l_norm THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END refresh_orders_0584;

PROCEDURE archive_invoices_0631 (p_val IN NUMBER, p_out OUT NUMBER) IS
    PROCEDURE helper IS
    BEGIN
        NULL;
    END helper;
BEGIN
    helper;
    BEGIN
        p_out := p_val * 50425;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            p_out := 50425;
    END;
    IF p_out > 50425 THEN
        p_out := 0;
    END IF;
END archive_invoices_0631;

end bench_s0064;
/
