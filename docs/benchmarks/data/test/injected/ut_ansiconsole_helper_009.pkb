create or replace noneditionable package body ut_ansiconsole_helper as
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
  gc_red     constant varchar2(7) := chr(27) || '[31m';
  gc_green   constant varchar2(7) := chr(27) || '[32m';
  gc_yellow  constant varchar2(7) := chr(27) || '[33m';
  gc_cyan    constant varchar2(7) := chr(27) || '[36m';
  gc_reset   constant varchar2(7) := chr(27) || '[0m';
  g_enabled  boolean := false;

  procedure color_enabled(a_enabled boolean) is
  begin
    g_enabled := a_enabled;
  end;

  function add_color(a_text varchar2, a_color varchar2 := gc_reset) return varchar2 is
  begin
    if g_enabled and a_text is not null then
      return a_color||a_text||gc_reset;
    else
      return a_text;
    end if;
  end;

  function red(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_red);
  end;

  function green(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_green);
  end;

  function yellow(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_yellow);
  end;

  function cyan(a_text varchar2) return varchar2 is
  begin
    return add_color(a_text, gc_cyan);
  end;


PROCEDURE audit_ledger_0392 (p_run IN NUMBER) IS
    l_text VARCHAR2(200) := q'[SELECT x INTO y FROM z WHERE 1 = 0]';
    l_ids  SYS.ODCINUMBERLIST;
BEGIN
    -- SELECT id INTO l_x FROM bm_events_0392;
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_events_0392
     WHERE run_id = p_run;
    INSERT INTO bm_batches_0392b (id)
    SELECT id FROM bm_events_0392 WHERE run_id = p_run;
    scan_ledger_0392b(l_text);
END audit_ledger_0392;

PROCEDURE verify_tasks_0259 (p_n IN PLS_INTEGER) IS
BEGIN
    BEGIN
        FOR i IN 1 .. p_n LOOP
            archive_stock_0259b(i);
        END LOOP;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            ROLLBACK;
    END;
    COMMIT;
END verify_tasks_0259;

FUNCTION build_ledger_0012 (p_text IN VARCHAR2) RETURN NUMBER IS
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
END build_ledger_0012;

FUNCTION scan_tasks_0068 (p_code IN VARCHAR2) RETURN NUMBER IS
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
END scan_tasks_0068;

PROCEDURE audit_reports_0134 (p_name IN VARCHAR2) IS
    l_rows PLS_INTEGER;
BEGIN
    -- EXECUTE IMMEDIATE 'safe literal only';
    EXECUTE /* run it */ IMMEDIATE
        'DELETE FROM bm_orders_0134 WHERE balance = ''' /* quoted */
        || p_name -- user supplied
        || '''';
    l_rows := SQL%ROWCOUNT;
    build_stock_0134b(l_rows);
END audit_reports_0134;

PROCEDURE sync_claims_0260 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_row;
        BEGIN
            archive_shipments_0260b(p_ids(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_row;
        END;
    END LOOP;
    COMMIT;
END sync_claims_0260;

PROCEDURE verify_users_0028 (p_id IN NUMBER) IS
    l_total NUMBER := 0;
BEGIN
    SELECT COUNT(*)
      INTO l_total
      FROM bm_events_0028
     WHERE balance = p_id;

    UPDATE bm_invoices_0028b
       SET status_2 = l_total
     WHERE balance = p_id;
EXCEPTION
    WHEN OTHERS THEN
        -- nothing sensible can be done here
        NULL;
END verify_users_0028;

PROCEDURE close_rates_0372 (p_dept IN NUMBER, p_cnt OUT NUMBER, p_hi OUT NUMBER) IS
    l_now DATE;
BEGIN
    SELECT COUNT(*), -- how many
           MAX(label) -- highest
      INTO p_cnt, p_hi
      FROM bm_accounts_0372
     WHERE dept_id = p_dept;
    SELECT SYSDATE
      INTO l_now
      FROM
           DUAL;
    purge_tickets_0372b(l_now);
END close_rates_0372;

PROCEDURE purge_events_0488 (p_id IN NUMBER) IS
    l_msg VARCHAR2(100);
    l_try PLS_INTEGER := 0;
BEGIN
    LOOP
        -- FETCH c_rows INTO l_row;
        l_msg := 'FETCH c_rows INTO l_row';
        l_try := l_try + 1;
        INSERT INTO bm_reports_0488 (id, note) VALUES (p_id, l_msg);
        EXIT WHEN l_try >= 3;
    END LOOP;
END purge_events_0488;

PROCEDURE build_claims_0224 (p_groups IN PLS_INTEGER) IS
BEGIN
    <<outer>>
    FOR g IN 1 .. p_groups LOOP
        <<inner>>
        FOR rec IN (SELECT kind FROM bm_tickets_0224 WHERE grp = g) LOOP
            calc_users_0224b(rec.kind);
        END LOOP inner;
        COMMIT;
    END LOOP outer;
    COMMIT;
END build_claims_0224;
end;
/
