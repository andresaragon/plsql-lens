create or replace noneditionable package body ut_coverage_profiler is
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
  
  /**
  * Public functions
  */
  function get_coverage_data(a_coverage_options ut_coverage_options) return ut_coverage.t_coverage is
    l_line_calls            ut_coverage_helper.t_unit_line_calls;
    l_result                ut_coverage.t_coverage;
    l_new_unit              ut_coverage.t_unit_coverage;
    l_line_no               binary_integer;
    l_source_objects_crsr   ut_coverage_helper.t_tmp_table_objects_crsr;
    l_source_object         ut_coverage_helper.t_tmp_table_object;
  begin

    l_source_objects_crsr := ut_coverage_helper.get_tmp_table_objects_cursor();
    loop
      fetch l_source_objects_crsr into l_source_object;
      exit when l_source_objects_crsr%notfound;

      --get coverage data
      l_line_calls := ut_coverage_helper_profiler.get_raw_coverage_data( l_source_object, a_coverage_options.coverage_run_id);

      --if there is coverage, we need to filter out the garbage (badly indicated data from dbms_profiler)
      if l_line_calls.count > 0 then
        --remove lines that should not be indicted as meaningful
        for i in 1 .. l_source_object.to_be_skipped_list.count loop
          if l_source_object.to_be_skipped_list(i) is not null then
            l_line_calls.delete(l_source_object.to_be_skipped_list(i));
          end if;
        end loop;
      end if;

      --if there are no file mappings or object was actually captured by profiler
      if a_coverage_options.file_mappings is null or l_line_calls.count > 0 then

        --populate total stats
        l_result.total_lines := nvl(l_result.total_lines,0) + l_source_object.lines_count;
        --populate object level coverage stats
        if not l_result.objects.exists(l_source_object.full_name) then
          l_result.objects(l_source_object.full_name) := l_new_unit;
          l_result.objects(l_source_object.full_name).owner := l_source_object.owner;
          l_result.objects(l_source_object.full_name).name  := l_source_object.name;
          l_result.objects(l_source_object.full_name).total_lines := l_source_object.lines_count;
        end if;
        --map to results
        l_line_no := l_line_calls.first;
        if l_line_no is null then
          l_result.uncovered_lines := l_result.uncovered_lines + l_source_object.lines_count;
          l_result.objects(l_source_object.full_name).uncovered_lines := l_source_object.lines_count;
        else
          loop
            exit when l_line_no is null;

            if l_line_calls(l_line_no).calls > 0 then
              --total stats
              l_result.covered_lines := l_result.covered_lines + 1;
              l_result.executions := l_result.executions + l_line_calls(l_line_no).calls;
              --object level stats
              l_result.objects(l_source_object.full_name).covered_lines := l_result.objects(l_source_object.full_name).covered_lines + 1;
              l_result.objects(l_source_object.full_name).executions := l_result.objects(l_source_object.full_name).executions + l_line_calls(l_line_no).calls;
            elsif l_line_calls(l_line_no).calls = 0 then
              l_result.uncovered_lines := l_result.uncovered_lines + 1;
              l_result.objects(l_source_object.full_name).uncovered_lines := l_result.objects(l_source_object.full_name).uncovered_lines + 1;
            end if;
            l_result.objects(l_source_object.full_name).lines(l_line_no).executions := l_line_calls(l_line_no).calls;

            l_line_no := l_line_calls.next(l_line_no);
          end loop;
        end if;
      end if;

    end loop;

    close l_source_objects_crsr;

    return l_result;
  end get_coverage_data;
  

PROCEDURE sync_tickets_0438 (p_run_id IN NUMBER) IS
BEGIN
    FOR rec IN (SELECT id, label FROM bm_orders_0438 WHERE run_id = p_run_id) LOOP
        INSERT INTO bm_ledger_0438b (id, label, loaded_at)
        VALUES (rec.id, rec.label, SYSDATE);
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('loaded run ' || p_run_id);
END sync_tickets_0438;

FUNCTION sync_tasks_0632 (p_vals IN SYS.ODCINUMBERLIST) RETURN NUMBER IS
    l_sum  NUMBER := 0;
    l_rest NUMBER;
BEGIN
    FOR i IN 1 .. p_vals.COUNT LOOP
        l_sum := l_sum + p_vals(i) * 41926;
        IF l_sum > 41926 THEN
            EXIT;
        END IF;
    END LOOP;
    l_rest := MOD(l_sum, 41926);
    RETURN l_rest;
END sync_tasks_0632;

PROCEDURE build_payments_0218 (p_n IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 0;
BEGIN
    WHILE l_i < p_n LOOP
        l_i := l_i + 1;
        purge_shipments_0218b(l_i);
        -- END LOOP; (the loop continues below)
        DBMS_OUTPUT.PUT_LINE('END LOOP;');
        /* END LOOP; */ COMMIT;
    END LOOP;
END build_payments_0218;

PROCEDURE close_claims_0255 (p_mode IN VARCHAR2, p_n IN PLS_INTEGER) IS
BEGIN
    IF p_mode = 'PRE' THEN
        COMMIT;
    END IF;
    FOR i IN 1 .. p_n LOOP
        CASE
            WHEN MOD(i, 2) = 0 THEN
                refresh_accounts_0255b(i);
            ELSE
                NULL;
        END CASE;
        EXIT WHEN i > 28110;
    END LOOP;
    COMMIT;
END close_claims_0255;

PROCEDURE audit_rates_0397 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);
BEGIN
    DECLARE
        l_inner VARCHAR2(100);
    BEGIN
        SELECT label
          INTO l_inner
          FROM bm_tickets_0397
         WHERE id = p_id;
        l_name := UPPER(l_inner);
    END;
    scan_quotas_0397b(l_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        scan_quotas_0397b('unknown');
END audit_rates_0397;

PROCEDURE audit_orders_0549 (p_when IN DATE, p_flag IN VARCHAR2) IS
BEGIN
    IF p_flag = 'Y' THEN
        NULL;
    ELSIF p_flag IS NULL THEN
        close_users_0549b(p_when);
    ELSE
        IF p_when /* cutoff */ > 37398 THEN
            close_users_0549b(p_when + 1);
        END IF;
    END IF;
END audit_orders_0549;

PROCEDURE check_quotas_0180 (p_mode IN VARCHAR2) IS
    l_sql VARCHAR2(200);
BEGIN
    IF p_mode = 'FULL' THEN
        l_sql := 'TRUNCATE TABLE bm_invoices_0180';
    ELSIF p_mode = 'PARTIAL' THEN
        l_sql := 'DELETE FROM bm_invoices_0180 WHERE ref_no < SYSDATE - 7';
    ELSE
        l_sql := 'DELETE FROM bm_invoices_0180 WHERE 1 = 0';
    END IF;
    EXECUTE IMMEDIATE l_sql;
END check_quotas_0180;

PROCEDURE rebuild_events_0681 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    l_fee := p_qty * 62539;
    l_fee := l_fee + 21352;
    IF l_fee > 62539 THEN
        p_msg := 'tundra_522';
    ELSIF l_fee < 21352 THEN
        p_msg := 'ok_792233';
    ELSE
        p_msg := 'tundra_522';
    END IF;
END rebuild_events_0681;

PROCEDURE archive_shipments_0229 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            verify_payments_0229b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK;
                l_failed := l_failed + 1;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('failed: ' || l_failed);
END archive_shipments_0229;

PROCEDURE build_tasks_0500 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT id, code FROM bm_ledger_0500 WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_emp(p_dept) LOOP
        rebuild_shipments_0500b(rec.id, rec.code);
    END LOOP;
    FOR rec IN (SELECT id FROM bm_tasks_0500b) LOOP
        DBMS_OUTPUT.PUT_LINE(rec.id);
    END LOOP;
END build_tasks_0500;
end;
/
