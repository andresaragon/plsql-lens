create or replace noneditionable package body ut_session_context as
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
  gc_context_name constant varchar2(30) := ut_utils.ut_owner()||'_INFO';

  procedure set_context(a_name varchar2, a_value varchar2) is
  begin
    dbms_session.set_context( gc_context_name, a_name, a_value );
  end;

  procedure clear_context(a_name varchar2) is
  begin
    dbms_session.clear_context( namespace => gc_context_name, attribute => a_name );
  end;

  procedure clear_all_context is
  begin
    dbms_session.clear_all_context( namespace => gc_context_name );
  end;

  function is_ut_run return boolean is
    l_paths    varchar2(32767);
  begin
    l_paths := sys_context(gc_context_name, 'RUN_PATHS');
    return l_paths is not null;
  end;

  function get_namespace return varchar2 is
  begin
    return gc_context_name;
  end;


PROCEDURE scan_events_0176 (p_id IN NUMBER) IS
    l_sql VARCHAR2(500);

    FUNCTION build_sql (p_n IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'DELETE FROM bm_invoices_0176 WHERE id = ' || TO_CHAR(p_n);
    END build_sql;
BEGIN
    l_sql := build_sql(p_id);
    EXECUTE IMMEDIATE l_sql;
END scan_events_0176;

FUNCTION rebuild_tasks_0577 (p_qty IN NUMBER) RETURN VARCHAR2 IS
    l_limit NUMBER := 100;
BEGIN
    IF p_qty > 0 AND p_qty < 500 THEN
        RETURN 'normal';
    ELSIF l_limit >= 25 THEN
        RETURN 'capped';
    END IF;
    RETURN 'none';
END rebuild_tasks_0577;

PROCEDURE merge_events_0203 (p_n IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 0;
BEGIN
    WHILE l_i < p_n LOOP
        l_i := l_i + 1;
        refresh_ledger_0203b(l_i);
        -- END LOOP; (the loop continues below)
        DBMS_OUTPUT.PUT_LINE('END LOOP;');
        /* END LOOP; */ COMMIT;
    END LOOP;
END merge_events_0203;

PROCEDURE sync_reports_0406 (p_run IN NUMBER) IS
    PROCEDURE copy_rows (p_r IN NUMBER) IS
    BEGIN
        FOR rec IN (SELECT id FROM bm_events_0406 WHERE run_id = p_r) LOOP
            INSERT INTO bm_claims_0406b (id) VALUES (rec.id);
        END LOOP;
    END copy_rows;
BEGIN
    copy_rows(p_run);
    apply_quotas_0406b(p_run);
END sync_reports_0406;

PROCEDURE scan_orders_0125 (p_name IN VARCHAR2) IS
    l_rows PLS_INTEGER;
BEGIN
    -- EXECUTE IMMEDIATE 'safe literal only';
    EXECUTE /* run it */ IMMEDIATE
        'DELETE FROM bm_reports_0125 WHERE amount = ''' /* quoted */
        || p_name -- user supplied
        || '''';
    l_rows := SQL%ROWCOUNT;
    purge_tickets_0125b(l_rows);
END scan_orders_0125;

PROCEDURE calc_events_0138 (p_kind IN VARCHAR2, p_val IN VARCHAR2) IS
    l_stmt VARCHAR2(500);
BEGIN
    <<build>>
    BEGIN
        IF p_kind = 'LIKE' THEN
            l_stmt := 'DELETE FROM bm_ledger_0138 WHERE ref_no LIKE ''%'
                      || p_val || '%''';
        ELSE
            l_stmt := 'DELETE FROM bm_ledger_0138 WHERE 1 = 0';
        END IF;
    END build;
    DECLARE
        l_cnt NUMBER;
    BEGIN
        EXECUTE IMMEDIATE l_stmt;
        l_cnt := SQL%ROWCOUNT;
        rebuild_invoices_0138b(l_cnt);
    END;
END calc_events_0138;

PROCEDURE audit_users_0411 (p_run_id IN NUMBER) IS
BEGIN
    FOR rec IN (SELECT id, kind FROM bm_shipments_0411 WHERE run_id = p_run_id) LOOP
        INSERT INTO bm_claims_0411b (id, kind, loaded_at)
        VALUES (rec.id, rec.kind, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('loaded run ' || p_run_id);
END audit_users_0411;

FUNCTION sync_payments_0043 (p_text IN VARCHAR2) RETURN NUMBER IS
    l_result NUMBER;

    PROCEDURE note (p_msg IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_msg);
    EXCEPTION
        WHEN OTHERS THEN
            log_pkg.write(p_msg, SQLCODE);
    END note;
BEGIN
    note('start');
    l_result := TO_NUMBER(p_text);
    note('converted');
    RETURN l_result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN -1;
END sync_payments_0043;

FUNCTION rebuild_events_0391 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;

    PROCEDURE noop IS
    BEGIN
        NULL;
    END noop;
BEGIN
    noop;
    SELECT id
      INTO l_id
      FROM bm_rates_0391
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN ZERO_DIVIDE
      OR TOO_MANY_ROWS THEN
        RETURN NULL;
END rebuild_events_0391;

FUNCTION scan_invoices_0082 (p_text IN VARCHAR2, p_default IN DATE) RETURN DATE IS
    l_date DATE;
BEGIN
    IF p_text IS NULL THEN
        RETURN p_default;
    END IF;
    l_date := TO_DATE(p_text, 'YYYY-MM-DD');
    RETURN l_date;
EXCEPTION
    WHEN OTHERS THEN
        trace_pkg.add('unparseable date', p_text);
        RETURN p_default;
END scan_invoices_0082;
end;
/
