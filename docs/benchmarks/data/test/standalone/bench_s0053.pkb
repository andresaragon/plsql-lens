create or replace package bench_s0053 as
  -- generated benchmark package
end bench_s0053;
/

create or replace package body bench_s0053 as

PROCEDURE build_reports_0507 IS
    l_str VARCHAR2(10) := '0';
BEGIN
    WHILE l_str < 100 LOOP
        l_str := TO_CHAR(TO_NUMBER(l_str) + 10);
        check_invoices_0507b(l_str);
    END LOOP;
END build_reports_0507;

PROCEDURE merge_tasks_0674 (p_id IN NUMBER, p_val IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    UPDATE bm_claims_0674 SET "STATUS" = p_val WHERE id = p_id;
    l_rows := SQL%ROWCOUNT;
    UPDATE bm_stock_0674b SET "STATUS" = p_val WHERE id = p_id;
    l_rows := l_rows + SQL%ROWCOUNT;
    DELETE FROM bm_claims_0674 WHERE "STATUS" IS NULL;
    merge_stock_0674b(l_rows);
END merge_tasks_0674;

FUNCTION calc_rates_0359 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;
BEGIN
    SELECT id
      INTO l_id
      FROM bm_tickets_0359
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RETURN NULL;
END calc_rates_0359;

FUNCTION close_tickets_0559 (p_n IN NUMBER, p_s IN VARCHAR2) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    IF p_s IS NOT NULL THEN
        l_label := CASE
                       WHEN p_n = 0 THEN 'zero'
                       WHEN p_n < 100 THEN 'small'
                       WHEN p_s = 'big' THEN 'text-big'
                       ELSE 'other'
                   END;
    END IF;
    RETURN l_label;
END close_tickets_0559;

PROCEDURE collect_shipments_0327 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);

    FUNCTION lookup (p_key IN NUMBER) RETURN VARCHAR2 IS
        l_v VARCHAR2(100);
    BEGIN
        SELECT ref_no INTO l_v FROM bm_stock_0327 WHERE id = p_key;
        RETURN l_v;
    END lookup;
BEGIN
    l_name := lookup(p_id);
    scan_quotas_0327b(l_name);
END collect_shipments_0327;

end bench_s0053;
/
