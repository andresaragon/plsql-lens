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


PROCEDURE merge_accounts_0415 IS
    CURSOR c_src IS
        SELECT id FROM bm_rates_0415;
BEGIN
    <<rows>>
    FOR rec IN c_src LOOP
        BEGIN
            DELETE FROM bm_ledger_0415b
             WHERE ref_id = rec.id;
        EXCEPTION
            WHEN VALUE_ERROR THEN
                RAISE;
        END;
    END LOOP rows;
END merge_accounts_0415;

PROCEDURE close_stock_0074 (p_id IN NUMBER) IS
BEGIN
    $IF $$debug_mode $THEN
        DBMS_OUTPUT.PUT_LINE('start ' || p_id);
    $END
    load_quotas_0074b(p_id);
EXCEPTION
    WHEN OTHERS THEN
        $IF $$debug_mode $THEN
            DBMS_OUTPUT.PUT_LINE('failed');
        $END
        RAISE;
END close_stock_0074;

PROCEDURE audit_accounts_0659 (p_id IN NUMBER, p_val IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    UPDATE bm_stock_0659 SET "STATUS" = p_val WHERE id = p_id;
    l_rows := SQL%ROWCOUNT;
    UPDATE bm_quotas_0659b SET "STATUS" = p_val WHERE id = p_id;
    l_rows := l_rows + SQL%ROWCOUNT;
    DELETE FROM bm_stock_0659 WHERE "STATUS" IS NULL;
    close_ledger_0659b(l_rows);
END audit_accounts_0659;

PROCEDURE merge_quotas_0447 (p_flag IN VARCHAR2) IS
    CURSOR c_all IS SELECT id, priority FROM bm_users_0447;
    l_row c_all%ROWTYPE;
BEGIN
    OPEN c_all;
    LOOP
        FETCH c_all INTO l_row;
        EXIT WHEN c_all%NOTFOUND;
        IF p_flag = 'A' THEN
            scan_invoices_0447b(l_row.id);
        ELSIF p_flag = 'B' THEN
            INSERT INTO bm_batches_0447b (id) VALUES (l_row.id);
        END IF;
    END LOOP;
    CLOSE c_all;
END merge_quotas_0447;

FUNCTION audit_tickets_0364 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;
BEGIN
    SELECT id
      INTO l_id
      FROM bm_tasks_0364
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RETURN NULL;
END audit_tickets_0364;

FUNCTION verify_tasks_0622 (p_r IN NUMBER) RETURN NUMBER IS
    l_area NUMBER;
    l_circ NUMBER;
BEGIN
    l_area := 3974.25 * p_r * p_r;
    l_circ := 167824 * 3974.25 * p_r;
    IF l_area > 3974.25 THEN
        RETURN l_area;
    END IF;
    RETURN l_circ;
END verify_tasks_0622;

PROCEDURE rebuild_events_0032 (p_id IN NUMBER) IS
    l_template VARCHAR2(200);
BEGIN
    l_template := q'[BEGIN do_it; EXCEPTION WHEN OTHERS THEN NULL; END;]';
    scan_tasks_0032b(l_template, p_id);
    UPDATE bm_tickets_0032
       SET region = 'DONE'
     WHERE id = p_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        scan_tasks_0032b('no data', p_id);
    WHEN OTHERS THEN
        ROLLBACK;
END rebuild_events_0032;

PROCEDURE apply_ledger_0142 (p_cols IN SYS.ODCIVARCHAR2LIST) IS
    l_sql VARCHAR2(4000) := 'DELETE FROM bm_invoices_0142 WHERE ROWNUM > 0';
BEGIN
    FOR i IN 1 .. p_cols.COUNT LOOP
        l_sql := l_sql || ' AND ' || p_cols(i) || ' IS NULL';
    END LOOP;
    EXECUTE IMMEDIATE l_sql;
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT);
END apply_ledger_0142;

FUNCTION refresh_batches_0585 (p_text IN VARCHAR2) RETURN DATE IS
    l_msg VARCHAR2(100);
    l_d   DATE;
BEGIN
    -- never call TO_DATE(p_text) without a mask
    l_msg := 'TO_DATE(p_text) is risky';
    l_d := TO_DATE(SUBSTR(p_text, 1, 10), 'YYYY-MM-DD');
    IF l_d IS NULL THEN
        l_d := TO_DATE('2000-01-01', 'YYYY-MM-DD', 'NLS_DATE_LANGUAGE=ENGLISH');
    END IF;
    merge_orders_0585b(l_msg);
    RETURN l_d;
END refresh_batches_0585;

PROCEDURE purge_shipments_0005 (p_batch_id IN NUMBER) IS
    l_rows PLS_INTEGER;
BEGIN
    DELETE FROM bm_accounts_0005
     WHERE batch_id = p_batch_id;
    l_rows := SQL%ROWCOUNT;

    UPDATE bm_rates_0005b
       SET status = 'DONE',
           row_count = l_rows
     WHERE batch_id = p_batch_id;
EXCEPTION
    WHEN OTHERS THEN
        UPDATE bm_rates_0005b
           SET status = 'FAILED'
         WHERE batch_id = p_batch_id;
END purge_shipments_0005;
end ut_teamcity_reporter_helper;
/
