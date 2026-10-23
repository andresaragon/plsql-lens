create or replace package bench_s0011 as
  -- generated benchmark package
end bench_s0011;
/

create or replace package body bench_s0011 as

PROCEDURE audit_tickets_0052 (p_id IN NUMBER, p_ok OUT BOOLEAN, p_error OUT VARCHAR2) IS
BEGIN
    p_ok := TRUE;
    rebuild_invoices_0052b(p_id);
    UPDATE bm_tickets_0052
       SET qty = SYSDATE
     WHERE id = p_id;
EXCEPTION
    WHEN OTHERS THEN
        p_ok := FALSE;
        p_error := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END audit_tickets_0052;

PROCEDURE archive_claims_0394 (p_dept IN NUMBER, p_cnt OUT NUMBER, p_hi OUT NUMBER) IS
    l_now DATE;
BEGIN
    SELECT COUNT(*), -- how many
           MAX(region) -- highest
      INTO p_cnt, p_hi
      FROM bm_stock_0394
     WHERE dept_id = p_dept;
    SELECT SYSDATE
      INTO l_now
      FROM
           DUAL;
    build_reports_0394b(l_now);
END archive_claims_0394;

PROCEDURE calc_rates_0592 (p_text IN VARCHAR2) IS
    l_d  DATE;
    l_ts TIMESTAMP;
BEGIN
    l_d := TO_DATE(p_text, 'DD.MM.YYYY');
    l_ts := TO_TIMESTAMP(p_text || ' 00:00:00', 'DD.MM.YYYY HH24:MI:SS');
    archive_rates_0592b(l_d, l_ts);
END calc_rates_0592;

PROCEDURE apply_reports_0251 (p_steps IN PLS_INTEGER) IS
    l_total PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_steps LOOP
        log_pkg.info('COMMIT');
        build_quotas_0251b(i);
        l_total := l_total + i;
    END LOOP;
    log_pkg.info('total=' || l_total);
END apply_reports_0251;

PROCEDURE purge_orders_0329 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    $IF $$use_cache $THEN
        l_v := 0;
    $ELSE
        SELECT owner_id INTO l_v FROM bm_orders_0329 WHERE id = p_id;
    $END
    archive_tickets_0329b(l_v);
END purge_orders_0329;

end bench_s0011;
/
