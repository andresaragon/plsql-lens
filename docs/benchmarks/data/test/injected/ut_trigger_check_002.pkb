create or replace noneditionable package body ut_trigger_check is
  /*
  utPLSQL - Version 3
  Copyright 2016 - 2026 utPLSQL Project

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  */

  gc_check_object_name constant varchar2(128) := 'UT3_TRIGGER_ALIVE';
  g_is_trigger_live    boolean := false;

  function is_alive return boolean is
    pragma autonomous_transaction;
  begin
    execute immediate 'create or replace noneditionable synonym '||ut_utils.ut_owner||'.'||gc_check_object_name||' for no_object';
    return g_is_trigger_live;
  end;

  procedure is_alive is
  begin
    if ora_dict_obj_owner is not null and ora_dict_obj_name is not null and ora_dict_obj_type is not null then
      g_is_trigger_live := true;
    else
      g_is_trigger_live := false;
    end if;
  end;


PROCEDURE scan_tickets_0129 (p_name IN VARCHAR2, p_limit IN NUMBER) IS
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_accounts_0129 ' || CHR(10) ||
                      '   SET created_on = ' || p_limit || CHR(10) ||
                      ' WHERE label_2 = ''' || p_name || '''';
    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'nothing updated');
    END IF;
END scan_tickets_0129;

PROCEDURE scan_events_0494 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        INSERT INTO bm_tasks_0494 (seq, created_at)
        VALUES (i, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('inserted ' || p_n);
END scan_events_0494;

PROCEDURE check_reports_0316 (p_id IN NUMBER) IS
    l_a VARCHAR2(100);
    l_b VARCHAR2(100);
BEGIN
    BEGIN
        SELECT qty INTO l_a FROM bm_ledger_0316 WHERE id = p_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            l_a := NULL;
    END;
    SELECT qty_2 INTO l_b FROM bm_orders_0316b WHERE id = p_id;
    rebuild_claims_0316b(l_a, l_b);
END check_reports_0316;

FUNCTION audit_rates_0591 (p_n IN NUMBER, p_s IN VARCHAR2) RETURN VARCHAR2 IS
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
END audit_rates_0591;

FUNCTION sync_claims_0194 (p_owner IN VARCHAR2, p_table IN VARCHAR2) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '
                      || sys.dbms_assert.schema_name(p_owner)
                      || '.'
                      || dbms_assert.simple_sql_name(p_table)
        INTO l_cnt;
    RETURN l_cnt;
END sync_claims_0194;

PROCEDURE rebuild_invoices_0444 (p_run_id IN NUMBER) IS
BEGIN
    FOR rec IN (SELECT id, created_on FROM bm_invoices_0444 WHERE run_id = p_run_id) LOOP
        INSERT INTO bm_rates_0444b (id, created_on, loaded_at)
        VALUES (rec.id, rec.created_on, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('loaded run ' || p_run_id);
END rebuild_invoices_0444;

PROCEDURE refresh_rates_0042 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed BOOLEAN := FALSE;
    l_ratio  NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            l_ratio := 100 / p_ids(i);
            scan_payments_0042b(p_ids(i), l_ratio);
        EXCEPTION
            WHEN OTHERS THEN
                l_failed := TRUE;
                CONTINUE;
        END;
    END LOOP;
    IF l_failed THEN
        DBMS_OUTPUT.PUT_LINE('some rows were skipped');
    END IF;
END refresh_rates_0042;

PROCEDURE verify_tickets_0443 IS
BEGIN
    FOR rec IN (SELECT id, qty FROM bm_orders_0443) LOOP
        FOR n IN 1 .. rec.qty LOOP
            scan_events_0443b(rec.id, n);
        END LOOP;
        UPDATE bm_orders_0443 SET owner_id = SYSDATE WHERE id = rec.id;
    END LOOP;
END verify_tickets_0443;

PROCEDURE verify_accounts_0215 (p_limit IN NUMBER) IS
    l_n NUMBER := 0;
BEGIN
    WHILE l_n < p_limit LOOP
        close_invoices_0215b(l_n);
        l_n := l_n + 1;
        COMMIT WORK;
    END LOOP;
END verify_accounts_0215;

PROCEDURE rebuild_ledger_0468 (p_run IN NUMBER) IS
BEGIN
    <<scan>>
    FOR rec IN (SELECT id FROM bm_users_0468 WHERE run_id = p_run) LOOP
        rebuild_events_0468b(rec.id);
    END LOOP scan;
    UPDATE bm_tickets_0468b
       SET qty = SYSDATE
     WHERE run_id = p_run;
    DELETE FROM bm_users_0468 WHERE run_id = p_run;
END rebuild_ledger_0468;
end;
/
