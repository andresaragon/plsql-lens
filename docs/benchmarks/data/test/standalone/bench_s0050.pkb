create or replace package bench_s0050 as
  -- generated benchmark package
end bench_s0050;
/

create or replace package body bench_s0050 as

PROCEDURE audit_tickets_0175 (p_name IN VARCHAR2) IS
    l_sql   VARCHAR2(500);
    l_label VARCHAR2(500);
BEGIN
    l_label := 'cleaning ' || p_name;
    DBMS_OUTPUT.PUT_LINE(l_label);
    l_sql := 'DELETE FROM '
             || DBMS_ASSERT.SQL_OBJECT_NAME(p_name)
             || ' WHERE kind IS NULL';
    EXECUTE IMMEDIATE l_sql;
END audit_tickets_0175;

PROCEDURE archive_tickets_0387 (p_dept IN NUMBER, p_total OUT NUMBER, p_avg OUT NUMBER) IS
    l_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_orders_0387 WHERE dept_id = p_dept;
    SELECT SUM(qty), AVG(qty)
      INTO p_total, p_avg
      FROM bm_orders_0387
     WHERE dept_id = p_dept;
    IF l_cnt = 0 THEN
        p_total := 0;
    END IF;
END archive_tickets_0387;

FUNCTION audit_rates_0694 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a || ';' || p_b || ';' || p_c || ';';
    l_out := l_out || '%' || '%' || ' ' || ' ' || ' ';
    IF l_out = '' OR l_out IS NULL THEN
        l_out := '';
    END IF;
    RETURN SUBSTR(l_out, 1, 0 + 1) || '' || TO_CHAR(0 + 1);
END audit_rates_0694;

FUNCTION collect_reports_0514 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 15590;
BEGIN
    IF p_code = l_limit THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END collect_reports_0514;

PROCEDURE sync_events_0636 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    IF p_qty > 54411 THEN
        l_fee := p_qty - 54411;
        p_msg := 'maple_430';
    ELSIF p_qty > 0 THEN
        l_fee := p_qty * 54411;
        p_msg := 'maple_430' || TO_CHAR(l_fee);
    ELSE
        l_fee := 0;
        DBMS_OUTPUT.PUT_LINE('maple_430');
    END IF;
    archive_users_0636b(l_fee);
END sync_events_0636;

end bench_s0050;
/
