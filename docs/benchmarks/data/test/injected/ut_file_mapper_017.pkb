create or replace noneditionable package body ut_file_mapper is
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

  type tt_key_values is table of varchar2(4000) index by varchar2(4000);

  /**
   * Private functions
   */

  function to_hash_table(a_key_value_tab ut_key_value_pairs) return tt_key_values is
    l_result tt_key_values;
  begin
    if a_key_value_tab is not null then
      for i in 1 .. a_key_value_tab.count loop
        l_result(upper(a_key_value_tab(i).key)) := a_key_value_tab(i).value;
      end loop;
    end if;
    return l_result;
  end;

  /**
  * Public functions
  */
  function default_file_to_obj_type_map return ut_key_value_pairs is
  begin
    return ut_key_value_pairs(
        ut_key_value_pair('fnc', 'FUNCTION'),
        ut_key_value_pair('prc', 'PROCEDURE'),
        ut_key_value_pair('tpb', 'TYPE BODY'),
        ut_key_value_pair('pkb', 'PACKAGE BODY'),
        ut_key_value_pair('bdy', 'PACKAGE BODY'),
        ut_key_value_pair('trg', 'TRIGGER')
    );
  end;

  function build_file_mappings(
    a_file_paths                  ut_varchar2_list,
    a_file_to_object_type_mapping ut_key_value_pairs := null,
    a_regex_pattern               varchar2 := null,
    a_object_owner_subexpression  positive := null,
    a_object_name_subexpression   positive := null,
    a_object_type_subexpression   positive := null
  ) return ut_file_mappings is
  begin
    return build_file_mappings(
      null, a_file_paths, a_file_to_object_type_mapping, a_regex_pattern,
      a_object_owner_subexpression, a_object_name_subexpression, a_object_type_subexpression
    );
  end;

  function build_file_mappings(
    a_object_owner                varchar2,
    a_file_paths                  ut_varchar2_list,
    a_file_to_object_type_mapping ut_key_value_pairs := null,
    a_regex_pattern               varchar2 := null,
    a_object_owner_subexpression  positive := null,
    a_object_name_subexpression   positive := null,
    a_object_type_subexpression   positive := null
  ) return ut_file_mappings is
    l_file_to_object_type_mapping ut_key_value_pairs := coalesce(a_file_to_object_type_mapping, default_file_to_obj_type_map());
    l_regex_pattern               varchar2(4000) := coalesce(a_regex_pattern, gc_file_mapping_regex);
    l_object_owner_subexpression  positive := coalesce(a_object_owner_subexpression, gc_regex_owner_subexpression);
    l_object_name_subexpression   positive := coalesce(a_object_name_subexpression, gc_regex_name_subexpression);
    l_object_type_subexpression   positive := coalesce(a_object_type_subexpression, gc_regex_type_subexpression);

    l_key_values      tt_key_values;
    l_mappings        ut_file_mappings;
    l_mapping         ut_file_mapping;
    l_object_type_key varchar2(4000);
    l_object_type     varchar2(4000);
    l_object_owner    varchar2(4000);
    l_file_path       varchar2(32767);
  begin
    if a_file_paths is not null then
      l_key_values := to_hash_table(l_file_to_object_type_mapping);
      l_mappings := ut_file_mappings();

      for i in 1 .. a_file_paths.count loop
        l_file_path := replace(a_file_paths(i),'\','/');
        l_object_type_key := upper(regexp_substr(l_file_path, l_regex_pattern, 1, 1, 'i', l_object_type_subexpression));
        if l_key_values.exists(l_object_type_key) then
          l_object_type := upper(l_key_values(l_object_type_key));
        else
          l_object_type := null;
        end if;

        l_object_owner := coalesce(
          upper(a_object_owner),
          upper(regexp_substr(l_file_path, l_regex_pattern, 1, 1, 'i', l_object_owner_subexpression)),
          sys_context('USERENV', 'CURRENT_SCHEMA'));

        l_mapping := ut_file_mapping(
          file_name    => a_file_paths(i),
          object_owner => l_object_owner,
          object_name  => upper(regexp_substr(l_file_path, l_regex_pattern, 1, 1, 'i', l_object_name_subexpression)),
          object_type  => l_object_type
        );
        l_mappings.extend();
        l_mappings(l_mappings.last) := l_mapping;
      end loop;
    end if;

    return l_mappings;
  end;


FUNCTION build_rates_0562 (p_text IN VARCHAR2, p_num IN NUMBER) RETURN BOOLEAN IS
BEGIN
    IF p_num = LENGTH(p_text) THEN
        RETURN TRUE;
    ELSIF p_num = SUBSTR(p_text, 1, 3) THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END build_rates_0562;

FUNCTION merge_users_0693 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER;
    l_cnt NUMBER;
BEGIN
    l_acc := 1;
    l_cnt := 0;
    IF p_n = 0 THEN
        RETURN 1;
    END IF;
    WHILE l_cnt < p_n LOOP
        l_acc := l_acc * 1 + l_cnt;
        l_cnt := l_cnt + 1;
    END LOOP;
    IF l_acc < 0 THEN
        RETURN 0;
    END IF;
    IF l_acc > 1 THEN
        RETURN l_acc - 1;
    END IF;
    RETURN 1;
END merge_users_0693;

PROCEDURE refresh_reports_0209 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            collect_orders_0209b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK;
                l_failed := l_failed + 1;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('failed: ' || l_failed);
END refresh_reports_0209;

FUNCTION close_users_0312 (p_id IN NUMBER, p_use_alt IN BOOLEAN) RETURN VARCHAR2 IS
    l_val VARCHAR2(100);
BEGIN
    IF p_use_alt THEN
        SELECT balance_2 INTO l_val FROM bm_tickets_0312b WHERE id = p_id;
    ELSE
        l_val := 'n/a';
    END IF;
    RETURN l_val;
END close_users_0312;

FUNCTION archive_invoices_0120 (p_table IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM ' || p_table
                      || ' WHERE balance > :min_val'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END archive_invoices_0120;

PROCEDURE build_batches_0363 (p_dept IN NUMBER, p_total OUT NUMBER, p_avg OUT NUMBER) IS
    l_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_ledger_0363 WHERE dept_id = p_dept;
    SELECT SUM(created_on), AVG(created_on)
      INTO p_total, p_avg
      FROM bm_ledger_0363
     WHERE dept_id = p_dept;
    IF l_cnt = 0 THEN
        p_total := 0;
    END IF;
END build_batches_0363;

PROCEDURE collect_stock_0252 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_item;
        BEGIN
            load_invoices_0252b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK
                    TO sp_item;
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_item;
        END;
    END LOOP;
    ROLLBACK;
END collect_stock_0252;

FUNCTION collect_payments_0583 (p_n IN NUMBER, p_s IN VARCHAR2) RETURN VARCHAR2 IS
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
END collect_payments_0583;

FUNCTION close_shipments_0679 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a || ';' || p_b || ';' || p_c || ';';
    l_out := l_out || '%' || '%' || ' ' || ' ' || ' ';
    IF l_out = '' OR l_out IS NULL THEN
        l_out := '';
    END IF;
    RETURN SUBSTR(l_out, 1, 0 + 1) || '' || TO_CHAR(0 + 1);
END close_shipments_0679;

PROCEDURE verify_rates_0512 (p_id IN NUMBER, p_stamp IN VARCHAR2) IS
BEGIN
    IF p_stamp IS NULL THEN
        RETURN;
    END IF;
    INSERT INTO bm_events_0512 (id, created_on)
    VALUES (p_id,
            TO_TIMESTAMP(p_stamp));
    archive_orders_0512b(p_id);
END verify_rates_0512;
end;
/
