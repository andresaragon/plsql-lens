create or replace noneditionable package body ut_teamcity_reporter_helper is
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

  subtype t_prop_index is varchar2(2000 char);
  type t_props is table of varchar2(32767) index by t_prop_index;

  function escape_value(a_value in varchar2) return varchar2 is
  begin
    return translate(regexp_replace(a_value, q'/(\'|\||\[|\]|/' || chr(13) || '|' || chr(10) || ')', '|\1'),chr(13)||chr(10),'rn');
  end;

  function message(a_command in varchar2, a_props t_props default cast(null as t_props)) return varchar2 is
    l_message varchar2(32767);
    l_index   t_prop_index;
    l_value   varchar2(32767);
    l_max_len binary_integer := 2000;
  begin
    l_message := '##teamcity[' || a_command || ' timestamp=''' ||
                 regexp_replace(to_char(systimestamp, 'YYYY-MM-DD"T"HH24:MI:ss.FF3TZHTZM'), '(\.\d{3})\d+(\+)', '\1\2') || '''';

    l_index := a_props.first;
    while l_index is not null loop
      if a_props(l_index) is not null then
        l_value   := escape_value(a_props(l_index));
        if length(l_value) > l_max_len then
          l_value   := substr(l_value,1,l_max_len-7)||escape_value('[...]');
        end if;
        l_message := l_message || ' ' || l_index || '=''' || l_value || '''';
      end if;
      l_index := a_props.next(l_index);
    end loop;
    l_message := l_message || ']';
    return l_message;

  end message;

  function test_suite_started(a_suite_name varchar2, a_flow_id varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_suite_name;
    l_props('flowId') := a_flow_id;
    return message('testSuiteStarted', l_props);
  end;
  function test_suite_finished(a_suite_name varchar2, a_flow_id varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_suite_name;
    l_props('flowId') := a_flow_id;
    return message('testSuiteFinished', l_props);
  end;

  function test_started(a_test_name varchar2, a_capture_standard_output boolean default null, a_flow_id varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_test_name;
    l_props('captureStandardOutput') := case a_capture_standard_output
                                          when true then
                                           'true'
                                          when false then
                                           'false'
                                        end;
    l_props('flowId') := a_flow_id;
    return message('testStarted', l_props);
  end;

  function test_finished(a_test_name varchar2, a_test_duration_milisec number default null, a_flow_id varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_test_name;
    l_props('duration') := a_test_duration_milisec;
    l_props('flowId') := a_flow_id;
    return message('testFinished', l_props);
  end;

  function test_disabled(a_test_name varchar2,a_msg varchar2 default null, a_flow_id varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_test_name;
    if a_msg is not null then
      l_props('message') := a_msg;
    end if;
    l_props('flowId') := a_flow_id;
    return message('testIgnored', l_props);
  end;
  function test_failed(a_test_name varchar2, a_msg in varchar2 default null, a_details varchar2 default null, a_flow_id varchar2 default null, a_actual varchar2 default null, a_expected varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_test_name;
    l_props('message') := a_msg;
    l_props('details') := a_details;
    l_props('flowId') := a_flow_id;

    if a_actual is not null and a_expected is not null then
      l_props('actual') := a_actual;
      l_props('expected') := a_expected;
    end if;

    return message('testFailed', l_props);
  end;

  function test_std_err(a_test_name varchar2, a_out in varchar2, a_flow_id in varchar2 default null) return varchar2 is
    l_props t_props;
  begin
    l_props('name') := a_test_name;
    l_props('out') := a_out;
    l_props('flowId') := a_flow_id;
    return message('testStdErr', l_props);
  end;


PROCEDURE close_payments_0326 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_name VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SELECT ref_no
          INTO l_name
          FROM bm_payments_0326
         WHERE id = p_ids(i);
        DBMS_OUTPUT.PUT_LINE(l_name);
    END LOOP;
END close_payments_0326;

PROCEDURE check_rates_0226 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        CASE MOD(i, 3)
            WHEN 0 THEN
                COMMIT;
            WHEN 1 THEN
                purge_invoices_0226b(i);
            ELSE
                NULL;
        END CASE;
    END LOOP;
END check_rates_0226;

PROCEDURE calc_invoices_0003 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed BOOLEAN := FALSE;
    l_ratio  NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            l_ratio := 100 / p_ids(i);
            load_events_0003b(p_ids(i), l_ratio);
        EXCEPTION
            WHEN OTHERS THEN
                l_failed := TRUE;
                CONTINUE;
        END;
    END LOOP;
    IF l_failed THEN
        DBMS_OUTPUT.PUT_LINE('some rows were skipped');
    END IF;
END calc_invoices_0003;

PROCEDURE calc_ledger_0200 (p_rc OUT SYS_REFCURSOR) IS
BEGIN
    -- OPEN p_rc FOR 'SELECT ' || p_rc;
    /* EXECUTE IMMEDIATE 'DROP TABLE x' || p_rc; */
    IF p_rc%ISOPEN THEN
        CLOSE p_rc;
    END IF;
    OPEN p_rc FOR
        'SELECT ''a || b'' AS joined, ref_no FROM bm_accounts_0200';
END calc_ledger_0200;

PROCEDURE purge_orders_0450 IS
    CURSOR c_old IS
        SELECT id FROM bm_rates_0450 WHERE region IS NULL;
    l_row c_old%ROWTYPE;
BEGIN
    OPEN c_old;
    LOOP
        FETCH c_old INTO l_row;
        EXIT WHEN c_old%NOTFOUND;
        DELETE FROM bm_tasks_0450b WHERE ref_id = l_row.id;
    END LOOP;
    CLOSE c_old;
END purge_orders_0450;

FUNCTION purge_users_0139 (p_table IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table
                      || ' WHERE status > :min_val'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END purge_users_0139;

PROCEDURE build_invoices_0493 (p_run_id IN NUMBER) IS
    TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_ids t_ids;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_stock_0493
     WHERE run_id = p_run_id;

    FORALL i IN 1 .. l_ids.COUNT
        UPDATE bm_reports_0493b
           SET balance = SYSDATE
         WHERE id = l_ids(i);
END build_invoices_0493;

PROCEDURE audit_claims_0490 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_errors PLS_INTEGER;
BEGIN
    FORALL i IN 1 .. p_ids.COUNT SAVE EXCEPTIONS
        DELETE FROM bm_claims_0490
         WHERE id = p_ids(i);
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -24381 THEN
            l_errors := SQL%BULK_EXCEPTIONS.COUNT;
            FOR j IN 1 .. l_errors LOOP
                DBMS_OUTPUT.PUT_LINE(SQL%BULK_EXCEPTIONS(j).ERROR_CODE);
            END LOOP;
        ELSE
            RAISE;
        END IF;
END audit_claims_0490;

PROCEDURE purge_quotas_0403 IS
    CURSOR c_src IS
        SELECT id FROM bm_claims_0403;
BEGIN
    <<rows>>
    FOR rec IN c_src LOOP
        BEGIN
            DELETE FROM bm_events_0403b
             WHERE ref_id = rec.id;
        EXCEPTION
            WHEN VALUE_ERROR THEN
                RAISE;
        END;
    END LOOP rows;
END purge_quotas_0403;

FUNCTION rebuild_invoices_0572 (p_text IN VARCHAR2) RETURN DATE IS
    l_to_date DATE;
    l_to_timestamp_text VARCHAR2(30);
BEGIN
    l_to_timestamp_text := 'n/a';
    l_to_date := my_to_date(p_text);
    IF l_to_date IS NULL THEN
        l_to_date := Pkg_Dates.Parse_Date(p_text, l_to_timestamp_text);
    END IF;
    RETURN l_to_date;
END rebuild_invoices_0572;
end ut_teamcity_reporter_helper;
/
