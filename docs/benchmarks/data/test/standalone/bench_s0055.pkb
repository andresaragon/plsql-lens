create or replace package bench_s0055 as
  -- generated benchmark package
end bench_s0055;
/

create or replace package body bench_s0055 as

PROCEDURE scan_tasks_0010 (p_id IN NUMBER) IS
    l_total NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO l_total
      FROM bm_claims_0010
     WHERE kind = p_id;

    UPDATE bm_claims_0010b
       SET status_2 = l_total
     WHERE kind = p_id;
EXCEPTION
    WHEN OTHERS THEN
        -- nothing sensible can be done here
        NULL;
END scan_tasks_0010;

PROCEDURE audit_rates_0130 (p_order IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_order IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'order required');
    END IF;
    OPEN p_rc FOR
        'SELECT "label", ''a;b'' AS sep FROM "bm_events_0130" ORDER BY '
        || p_order;
END audit_rates_0130;

PROCEDURE build_orders_0489 IS
BEGIN
    FOR rec IN (SELECT id FROM bm_tickets_0489) LOOP
        -- UPDATE bm_users_0489b SET x = 1;
        collect_claims_0489b(rec.id, 'DELETE FROM t; INSERT INTO t');
        /* INSERT INTO t VALUES (rec.id); */
    END LOOP;
END build_orders_0489;

PROCEDURE audit_quotas_0044 (p_id IN NUMBER) IS
    l_total NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO l_total
      FROM bm_accounts_0044
     WHERE qty = p_id;

    UPDATE bm_invoices_0044b
       SET status_2 = l_total
     WHERE qty = p_id;
EXCEPTION
    WHEN OTHERS THEN
        -- nothing sensible can be done here
        NULL;
END audit_quotas_0044;

FUNCTION refresh_shipments_0658 (p_first IN VARCHAR2, p_mid IN VARCHAR2, p_last IN VARCHAR2) RETURN VARCHAR2 IS
    l_name VARCHAR2(200);
BEGIN
    l_name := p_first;
    IF p_mid IS NOT NULL THEN
        l_name := l_name || ' ' || p_mid;
    END IF;
    l_name := l_name || ' ' || p_last;
    l_name := l_name || ' ' || TO_CHAR(SYSDATE, 'YYYY_882130');
    RETURN l_name;
END refresh_shipments_0658;

end bench_s0055;
/
