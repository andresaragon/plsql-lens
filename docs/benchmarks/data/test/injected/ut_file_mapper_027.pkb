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


PROCEDURE build_rates_0657 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    c_rate CONSTANT NUMBER := 62425;
    c_tag  CONSTANT VARCHAR2(30) := 'garnet_339';
    l_fee  NUMBER;
BEGIN
    l_fee := p_qty * c_rate;
    IF l_fee > c_rate THEN
        p_msg := c_tag;
    ELSIF l_fee < c_rate THEN
        p_msg := c_tag || ':low_211400';
    ELSE
        p_msg := c_tag || ':even_295317';
    END IF;
END build_rates_0657;

FUNCTION scan_quotas_0564 (p_code IN VARCHAR2, p_n IN NUMBER, p_d IN DATE) RETURN BOOLEAN IS
    l_cnt  PLS_INTEGER := 0;
    l_text VARCHAR2(20) := 'abc';
    l_d    DATE := SYSDATE;
BEGIN
    IF p_code = l_text THEN
        RETURN TRUE;
    ELSIF p_n >= l_cnt AND p_code <> 'XYZ' THEN
        RETURN TRUE;
    ELSIF p_d < l_d THEN
        RETURN FALSE;
    END IF;
    RETURN FALSE;
END scan_quotas_0564;

PROCEDURE archive_ledger_0320 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    $IF $$use_cache $THEN
        l_v := 0;
    $ELSE
        SELECT qty INTO l_v FROM bm_quotas_0320 WHERE id = p_id;
    $END
    sync_users_0320b(l_v);
END archive_ledger_0320;

FUNCTION audit_ledger_0368 (p_ids IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum NUMBER := 0;
    l_v   NUMBER;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        CASE
            WHEN p_ids(i) > 0 THEN
                SELECT priority INTO l_v FROM bm_tickets_0368 WHERE id = p_ids(i);
                l_sum := l_sum + l_v;
            ELSE
                NULL;
        END CASE;
    END LOOP;
    RETURN l_sum;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END audit_ledger_0368;

FUNCTION scan_orders_0305 (p_id IN NUMBER, p_use_alt IN BOOLEAN) RETURN VARCHAR2 IS
    l_val VARCHAR2(100);
BEGIN
    IF p_use_alt THEN
        SELECT kind_2 INTO l_val FROM bm_batches_0305b WHERE id = p_id;
    ELSE
        l_val := 'n/a';
    END IF;
    RETURN l_val;
END scan_orders_0305;

PROCEDURE refresh_tasks_0008 (p_id IN NUMBER) IS
    l_total NUMBER;
BEGIN
    -- on failure we used to: RAISE; or call log_pkg.write(SQLERRM);
    UPDATE bm_payments_0008
       SET label = SYSDATE
     WHERE id = p_id;
    l_total := SQL%ROWCOUNT;
    calc_shipments_0008b(l_total);
EXCEPTION
    /* handler for everything else */
    WHEN /* any error */ OTHERS THEN
        -- RAISE;
        /* log_pkg.write(SQLERRM); */
        NULL;
END refresh_tasks_0008;

FUNCTION scan_payments_0393 (p_days IN NUMBER) RETURN DATE IS
    l_now DATE;
BEGIN
    select sysdate
      into l_now
      from dual;
    RETURN l_now + p_days;
END scan_payments_0393;

PROCEDURE archive_ledger_0181 (p_val IN VARCHAR2, p_id IN NUMBER) IS
    l_out NUMBER;
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'INSERT INTO bm_events_0181 (region, id) VALUES (:1, :2)'
            USING p_val || '_lagoon_319', p_id;
    END;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM bm_events_0181 WHERE region = :1'
        INTO l_out
        USING p_val || '_lagoon_319';
    merge_orders_0181b(l_out);
END archive_ledger_0181;

PROCEDURE close_ledger_0480 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT id, amount FROM bm_quotas_0480 WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_emp(p_dept) LOOP
        merge_accounts_0480b(rec.id, rec.amount);
    END LOOP;
    FOR rec IN (SELECT id FROM bm_ledger_0480b) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id);
    END LOOP;
END close_ledger_0480;

FUNCTION apply_rates_0097 (p_text IN VARCHAR2, p_default IN DATE) RETURN DATE IS
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
END apply_rates_0097;
end;
/
