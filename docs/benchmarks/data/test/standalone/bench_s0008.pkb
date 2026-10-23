create or replace package bench_s0008 as
  -- generated benchmark package
end bench_s0008;
/

create or replace package body bench_s0008 as

FUNCTION close_shipments_0582 (p_text IN VARCHAR2) RETURN DATE IS
    l_to_date DATE;
    l_to_timestamp_text VARCHAR2(30);
BEGIN
    l_to_timestamp_text := 'n/a';
    l_to_date := my_to_date(p_text);
    IF l_to_date IS NULL THEN
        l_to_date := Pkg_Dates.Parse_Date(p_text, l_to_timestamp_text);
    END IF;
    RETURN l_to_date;
END close_shipments_0582;

PROCEDURE collect_quotas_0164 (p_rc OUT SYS_REFCURSOR) IS
    l_sql VARCHAR2(500);
BEGIN
    EXECUTE IMMEDIATE q'[
        UPDATE bm_batches_0164
           SET priority = 'ACTIVE'
         WHERE kind_2 IS NULL
    ]';
    l_sql := q'[SELECT priority FROM bm_batches_0164 WHERE priority = 'ACTIVE']';
    OPEN p_rc FOR l_sql;
END collect_quotas_0164;

FUNCTION merge_payments_0590 (p_qty IN NUMBER) RETURN VARCHAR2 IS
    l_limit NUMBER := 100;
BEGIN
    IF p_qty > 0 AND p_qty < 500 THEN
        RETURN 'normal';
    ELSIF l_limit >= 25 THEN
        RETURN 'capped';
    END IF;
    RETURN 'none';
END merge_payments_0590;

PROCEDURE merge_claims_0202 (p_groups IN PLS_INTEGER) IS
BEGIN
    <<outer>>
    FOR g IN 1 .. p_groups LOOP
        <<inner>>
        FOR rec IN (SELECT kind FROM bm_quotas_0202 WHERE grp = g) LOOP
            purge_accounts_0202b(rec.kind);
        END LOOP inner;
        COMMIT;
    END LOOP outer;
    COMMIT;
END merge_claims_0202;

PROCEDURE load_quotas_0525 (p_text IN VARCHAR2) IS
    l_d DATE;
BEGIN
    l_d := TO_DATE(p_text);
    IF l_d > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20010, 'date in the future');
    END IF;
    load_claims_0525b(l_d);
END load_quotas_0525;

end bench_s0008;
/
