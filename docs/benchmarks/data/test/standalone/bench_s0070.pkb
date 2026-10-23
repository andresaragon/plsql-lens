create or replace package bench_s0070 as
  -- generated benchmark package
end bench_s0070;
/

create or replace package body bench_s0070 as

PROCEDURE check_invoices_0374 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);
BEGIN
    DECLARE
        l_inner VARCHAR2(100);
    BEGIN
        SELECT label
          INTO l_inner
          FROM bm_shipments_0374
         WHERE id = p_id;
        l_name := UPPER(l_inner);
    END;
    scan_users_0374b(l_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        scan_users_0374b('unknown');
END check_invoices_0374;

FUNCTION load_accounts_0687 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a || ';' || p_b || ';' || p_c || ';';
    l_out := l_out || '%' || '%' || ' ' || ' ' || ' ';
    IF l_out = '' OR l_out IS NULL THEN
        l_out := '';
    END IF;
    RETURN SUBSTR(l_out, 1, 0 + 1) || '' || TO_CHAR(0 + 1);
END load_accounts_0687;

PROCEDURE purge_shipments_0131 (p_order IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
BEGIN
    IF p_order IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'order required');
    END IF;
    OPEN p_rc FOR
        'SELECT "region", ''a;b'' AS sep FROM "bm_claims_0131" ORDER BY '
        || p_order;
END purge_shipments_0131;

PROCEDURE archive_payments_0367 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);
BEGIN
    DECLARE
        l_inner VARCHAR2(100);
    BEGIN
        SELECT label
          INTO l_inner
          FROM bm_rates_0367
         WHERE id = p_id;
        l_name := UPPER(l_inner);
    END;
    load_users_0367b(l_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        load_users_0367b('unknown');
END archive_payments_0367;

PROCEDURE scan_accounts_0315 (p_id IN NUMBER, p_label IN VARCHAR2) IS
    l_owner VARCHAR2(100);
BEGIN
    INSERT INTO bm_shipments_0315 (id, label) VALUES (p_id, p_label);
    SELECT code INTO l_owner
      FROM bm_quotas_0315b
     WHERE id = p_id;
    apply_orders_0315b(l_owner);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE bm_shipments_0315 SET label = p_label WHERE id = p_id;
END scan_accounts_0315;

end bench_s0070;
/
