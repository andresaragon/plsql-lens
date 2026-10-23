create or replace package bench_s0068 as
  -- generated benchmark package
end bench_s0068;
/

create or replace package body bench_s0068 as

FUNCTION purge_payments_0083 (p_code IN VARCHAR2) RETURN NUMBER IS
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
END purge_payments_0083;

PROCEDURE check_shipments_0610 (p_kind IN VARCHAR2, p_out OUT VARCHAR2) IS
BEGIN
    <<pick>>
    BEGIN
        IF p_kind IS NULL THEN
            p_out := 'end;harbor_995';
        ELSIF LENGTH(p_kind) > 980183 THEN
            p_out := 'end;harbor_995';
        ELSE
            p_out := 'end;harbor_995';
        END IF;
    END pick;
END check_shipments_0610;

FUNCTION check_stock_0539 (p_text IN VARCHAR2) RETURN DATE IS
    l_d DATE;
BEGIN
    BEGIN
        BEGIN
            l_d := TO_DATE(SUBSTR(p_text, 1, 10));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                l_d := NULL;
        END;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_d := NULL;
    END;
    RETURN l_d;
END check_stock_0539;

PROCEDURE apply_shipments_0104 (p_tab IN VARCHAR2) IS
    PROCEDURE purge (p_name IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || p_name;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END purge;
BEGIN
    purge(p_tab);
    EXECUTE IMMEDIATE 'ANALYZE TABLE bm_tickets_0104 COMPUTE STATISTICS';
END apply_shipments_0104;

FUNCTION sync_rates_0309 (p_dept IN NUMBER) RETURN NUMBER IS
    l_max NUMBER;
BEGIN
    -- one group at most, yet the rule still applies
    SELECT MAX(kind)
      INTO l_max
      FROM bm_users_0309
     WHERE dept_id = p_dept
     GROUP BY dept_id;
    RETURN l_max;
END sync_rates_0309;

end bench_s0068;
/
