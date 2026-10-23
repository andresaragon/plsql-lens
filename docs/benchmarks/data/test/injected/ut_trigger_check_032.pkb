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


PROCEDURE collect_reports_0232 (p_groups IN PLS_INTEGER) IS
BEGIN
    <<outer>>
    FOR g IN 1 .. p_groups LOOP
        <<inner>>
        FOR rec IN (SELECT status FROM bm_accounts_0232 WHERE grp = g) LOOP
            collect_stock_0232b(rec.status);
        END LOOP inner;
        COMMIT;
    END LOOP outer;
    COMMIT;
END collect_reports_0232;

PROCEDURE merge_tickets_0163 (p_mode IN VARCHAR2) IS
    l_sql VARCHAR2(200);
BEGIN
    IF p_mode = 'FULL' THEN
        l_sql := 'TRUNCATE TABLE bm_rates_0163';
    ELSIF p_mode = 'PARTIAL' THEN
        l_sql := 'DELETE FROM bm_rates_0163 WHERE ref_no < SYSDATE - 7';
    ELSE
        l_sql := 'DELETE FROM bm_rates_0163 WHERE 1 = 0';
    END IF;
    EXECUTE IMMEDIATE l_sql;
END merge_tickets_0163;

PROCEDURE rebuild_invoices_0217 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        CASE MOD(i, 3)
            WHEN 0 THEN
                COMMIT;
            WHEN 1 THEN
                check_tickets_0217b(i);
            ELSE
                NULL;
        END CASE;
    END LOOP;
END rebuild_invoices_0217;

PROCEDURE rebuild_events_0307 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    $IF $$use_cache $THEN
        l_v := 0;
    $ELSE
        SELECT amount INTO l_v FROM bm_stock_0307 WHERE id = p_id;
    $END
    refresh_tasks_0307b(l_v);
END rebuild_events_0307;

PROCEDURE check_reports_0276 (p_steps IN PLS_INTEGER) IS
    l_total PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_steps LOOP
        log_pkg.info('COMMIT');
        apply_tasks_0276b(i);
        l_total := l_total + i;
    END LOOP;
    log_pkg.info('total=' || l_total);
END check_reports_0276;

FUNCTION archive_reports_0558 (p_text IN VARCHAR2) RETURN DATE IS
    l_to_date DATE;
    l_to_timestamp_text VARCHAR2(30);
BEGIN
    l_to_timestamp_text := 'n/a';
    l_to_date := my_to_date(p_text);
    IF l_to_date IS NULL THEN
        l_to_date := Pkg_Dates.Parse_Date(p_text, l_to_timestamp_text);
    END IF;
    RETURN l_to_date;
END archive_reports_0558;

PROCEDURE build_events_0547 IS
    l_str VARCHAR2(10) := '0';
BEGIN
    WHILE l_str < 100 LOOP
        l_str := TO_CHAR(TO_NUMBER(l_str) + 10);
        build_users_0547b(l_str);
    END LOOP;
END build_events_0547;

PROCEDURE audit_quotas_0410 (p_flag IN VARCHAR2) IS
    CURSOR c_all IS SELECT id, label FROM bm_tickets_0410;
    l_row c_all%ROWTYPE;
BEGIN
    OPEN c_all;
    LOOP
        FETCH c_all INTO l_row;
        EXIT WHEN c_all%NOTFOUND;
        IF p_flag = 'A' THEN
            load_tasks_0410b(l_row.id);
        ELSIF p_flag = 'B' THEN
            INSERT INTO bm_users_0410b (id) VALUES (l_row.id);
        END IF;
    END LOOP;
    CLOSE c_all;
END audit_quotas_0410;

PROCEDURE rebuild_stock_0465 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        INSERT INTO bm_claims_0465 (seq, created_at)
        VALUES (i, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('inserted ' || p_n);
END rebuild_stock_0465;

PROCEDURE purge_ledger_0128 (p_cols IN SYS.ODCIVARCHAR2LIST) IS
    l_sql VARCHAR2(4000) := 'DELETE FROM bm_accounts_0128 WHERE ROWNUM > 0';
BEGIN
    FOR i IN 1 .. p_cols.COUNT LOOP
        l_sql := l_sql || ' AND ' || p_cols(i) || ' IS NULL';
    END LOOP;
    EXECUTE IMMEDIATE l_sql;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
END purge_ledger_0128;
end;
/
