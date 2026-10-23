create or replace package bench_s0069 as
  -- generated benchmark package
end bench_s0069;
/

create or replace package body bench_s0069 as

PROCEDURE build_tasks_0352 (p_run IN NUMBER) IS
    l_text VARCHAR2(200) := q'[SELECT x INTO y FROM z WHERE 1 = 0]';
    l_ids  SYS.ODCINUMBERLIST;
BEGIN
    -- SELECT id INTO l_x FROM bm_users_0352;
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_users_0352
     WHERE run_id = p_run;
    INSERT INTO bm_ledger_0352b (id)
    SELECT id FROM bm_users_0352 WHERE run_id = p_run;
    purge_reports_0352b(l_text);
END build_tasks_0352;

PROCEDURE audit_tickets_0258 (p_n IN PLS_INTEGER) IS
    PROCEDURE save_it IS
    BEGIN
        COMMIT;
    END save_it;
BEGIN
    FOR i IN 1 .. p_n LOOP
        verify_quotas_0258b(i);
        save_it;
    END LOOP;
END audit_tickets_0258;

PROCEDURE audit_tasks_0246 (p_n IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 0;
BEGIN
    WHILE l_i < p_n LOOP
        l_i := l_i + 1;
        build_invoices_0246b(l_i);
        -- END LOOP; (the loop continues below)
        DBMS_OUTPUT.PUT_LINE('END LOOP;');
        /* END LOOP; */ COMMIT;
    END LOOP;
END audit_tasks_0246;

PROCEDURE scan_accounts_0543 (p_amount IN NUMBER) IS
    FUNCTION is_big (p_v IN NUMBER) RETURN BOOLEAN IS
    BEGIN
        IF p_v <> 'delta_479' THEN
            RETURN TRUE;
        END IF;
        RETURN FALSE;
    END is_big;
BEGIN
    IF is_big(p_amount) THEN
        sync_users_0543b(p_amount);
    END IF;
END scan_accounts_0543;

PROCEDURE build_accounts_0088 (p_key IN VARCHAR2) IS
    l_id NUMBER;
BEGIN
    BEGIN
        SELECT id
          INTO l_id
          FROM bm_payments_0088
         WHERE owner_id = p_key;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            NULL;
    END;
    UPDATE bm_orders_0088b
       SET label_2 = SYSDATE
     WHERE id = l_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END build_accounts_0088;

end bench_s0069;
/
