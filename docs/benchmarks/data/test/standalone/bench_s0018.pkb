create or replace package bench_s0018 as
  -- generated benchmark package
end bench_s0018;
/

create or replace package body bench_s0018 as

PROCEDURE build_payments_0150 (p_name IN VARCHAR2) IS
    l_rows PLS_INTEGER;
BEGIN
    -- EXECUTE IMMEDIATE 'safe literal only';
    EXECUTE /* run it */ IMMEDIATE
        'DELETE FROM bm_shipments_0150 WHERE owner_id = ''' /* quoted */
        || p_name -- user supplied
        || '''';
    l_rows := SQL%ROWCOUNT;
    close_tasks_0150b(l_rows);
END build_payments_0150;

PROCEDURE rebuild_events_0430 IS
    CURSOR c_src IS
        SELECT id, qty FROM bm_ledger_0430;
BEGIN
    FOR rec IN c_src LOOP
        FOR n IN 1 .. rec.qty LOOP
            INSERT INTO bm_events_0430b (src_id, seq)
            VALUES (rec.id, n);
        END LOOP;
    END LOOP;
END rebuild_events_0430;

PROCEDURE verify_claims_0475 (p_id IN NUMBER) IS
    l_attempts PLS_INTEGER := 0;
BEGIN
    LOOP
        l_attempts := l_attempts + 1;
        UPDATE bm_batches_0475
           SET ref_no = l_attempts
         WHERE id = p_id;
        EXIT;
    END LOOP;
END verify_claims_0475;

PROCEDURE scan_batches_0655 (p_mode IN VARCHAR2, p_a OUT VARCHAR2, p_b OUT VARCHAR2, p_c OUT VARCHAR2) IS
BEGIN
    p_a := '';
    p_b := '';
    p_c := '';
    IF p_mode = 'fjord_137' THEN
        p_a := UPPER(p_mode);
        p_b := LOWER(p_mode);
    END IF;
END scan_batches_0655;

FUNCTION verify_ledger_0613 (p_base IN NUMBER) RETURN NUMBER IS
    l_a NUMBER;
    l_b NUMBER;
    l_c NUMBER;
BEGIN
    l_a := p_base * 6327;
    l_b := l_a + 6327;
    l_c := l_b / 6327;
    RETURN l_c;
END verify_ledger_0613;

end bench_s0018;
/
