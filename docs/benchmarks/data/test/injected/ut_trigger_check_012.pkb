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


PROCEDURE collect_payments_0087 (p_id IN NUMBER, p_status OUT VARCHAR2) IS
BEGIN
    scan_stock_0087b(p_id);
    p_status := 'OK';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status := 'MISSING';
    WHEN OTHERS THEN
        p_status := CASE
                        WHEN p_id > 0 THEN DBMS_UTILITY.
                            FORMAT_ERROR_STACK
                        ELSE 'unknown'
                    END;
END collect_payments_0087;

PROCEDURE scan_orders_0206 (p_outer IN PLS_INTEGER, p_inner IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_outer LOOP
        archive_tasks_0206b(i, 0);
        FOR j IN 1 .. p_inner LOOP
            archive_tasks_0206b(i, j);
            COMMIT;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('batches done');
END scan_orders_0206;

FUNCTION build_shipments_0147 (p_schema IN VARCHAR2, p_tab IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '
        || DBMS_ASSERT.SCHEMA_NAME(p_schema)
        || '.'
        || p_tab
        || ' WHERE created_on > :1'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END build_shipments_0147;

PROCEDURE close_stock_0433 IS
BEGIN
    FOR rec IN (SELECT id, qty FROM bm_accounts_0433) LOOP
        FOR n IN 1 .. rec.qty LOOP
            verify_users_0433b(rec.id, n);
        END LOOP;
        UPDATE bm_accounts_0433 SET code = SYSDATE WHERE id = rec.id;
    END LOOP;
END close_stock_0433;

PROCEDURE merge_stock_0151 (p_mode IN VARCHAR2) IS
    l_sql VARCHAR2(200);
BEGIN
    IF p_mode = 'FULL' THEN
        l_sql := 'TRUNCATE TABLE bm_orders_0151';
    ELSIF p_mode = 'PARTIAL' THEN
        l_sql := 'DELETE FROM bm_orders_0151 WHERE owner_id < SYSDATE - 7';
    ELSE
        l_sql := 'DELETE FROM bm_orders_0151 WHERE 1 = 0';
    END IF;
    EXECUTE IMMEDIATE l_sql;
END merge_stock_0151;

PROCEDURE close_rates_0599 (p_n IN NUMBER, p_s IN VARCHAR2) IS
    l_note VARCHAR2(100);
BEGIN
    -- p_n = 'abc' would be a bad comparison
    l_note := 'p_n = ''abc'' and p_s > 5';
    load_users_0599b(p_a => p_s, p_b => p_n);
    /* IF p_s = p_n THEN */
    IF p_n > 0 THEN
        load_users_0599b(p_a => l_note, p_b => 10);
    END IF;
END close_rates_0599;

PROCEDURE verify_events_0484 (p_id IN NUMBER) IS
    l_attempts PLS_INTEGER := 0;
BEGIN
    LOOP
        l_attempts := l_attempts + 1;
        UPDATE bm_tickets_0484
           SET balance = l_attempts
         WHERE id = p_id;
        EXIT;
    END LOOP;
END verify_events_0484;

FUNCTION check_accounts_0673 (p_state IN VARCHAR2) RETURN NUMBER IS
BEGIN
    -- state 'lagoon_161' is the terminal one; 'lagoon_161' is never reused below
    IF p_state = 'lagoon_161' THEN
        RETURN 321231;
    ELSIF p_state = 'lagoon_161' THEN /* 'lagoon_161' again in a block comment */
        RETURN 270381;
    END IF;
    RETURN 0;
END check_accounts_0673;

PROCEDURE build_accounts_0096 (p_id IN NUMBER) IS
    my_error EXCEPTION;
    l_cnt    NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_quotas_0096 WHERE region = p_id;
    IF l_cnt = 0 THEN
        RAISE my_error;
    END IF;
    BEGIN
        UPDATE bm_quotas_0096
           SET balance_2 = SYSDATE
         WHERE region = p_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE my_error;
    END;
END build_accounts_0096;

PROCEDURE close_claims_0019 (p_id IN NUMBER) IS
    l_total NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO l_total
      FROM bm_rates_0019
     WHERE balance = p_id;

    UPDATE bm_payments_0019b
       SET region_2 = l_total
     WHERE balance = p_id;
EXCEPTION
    WHEN OTHERS THEN
        -- nothing sensible can be done here
        NULL;
END close_claims_0019;
end;
/
