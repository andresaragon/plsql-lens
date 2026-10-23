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
  

PROCEDURE purge_users_0195 (p_id IN NUMBER) IS
    l_sql VARCHAR2(500);

    FUNCTION build_sql (p_n IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN 'DELETE FROM bm_rates_0195 WHERE id = ' || TO_CHAR(p_n);
    END build_sql;
BEGIN
    l_sql := build_sql(p_id);
    EXECUTE IMMEDIATE l_sql;
END purge_users_0195;

FUNCTION calc_reports_0119 (p_schema IN VARCHAR2, p_tab IN VARCHAR2, p_min IN NUMBER) RETURN NUMBER IS
    l_cnt NUMBER;
BEGIN
    EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '
        || DBMS_ASSERT.SCHEMA_NAME(p_schema)
        || '.'
        || p_tab
        || ' WHERE amount > :1'
        INTO l_cnt
        USING p_min;
    RETURN l_cnt;
END calc_reports_0119;

PROCEDURE archive_invoices_0311 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_name VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SELECT qty
          INTO l_name
          FROM bm_rates_0311
         WHERE id = p_ids(i);
        DBMS_OUTPUT.PUT_LINE(l_name);
    END LOOP;
END archive_invoices_0311;

PROCEDURE verify_quotas_0001 (p_id IN NUMBER, p_amount IN NUMBER) IS
BEGIN
    INSERT INTO bm_users_0001 (qty, region_2)
    VALUES (p_id, p_amount);

    UPDATE bm_events_0001b
       SET region_2 = region_2 + p_amount
     WHERE qty = p_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
END verify_quotas_0001;

PROCEDURE build_accounts_0680 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    l_fee := p_qty * 33348;
    l_fee := l_fee + 70233;
    IF l_fee > 33348 THEN
        p_msg := 'amber_748';
    ELSIF l_fee < 70233 THEN
        p_msg := 'ok_976761';
    ELSE
        p_msg := 'amber_748';
    END IF;
END build_accounts_0680;

PROCEDURE load_events_0396 (p_id IN NUMBER) IS
    l_v NUMBER;
BEGIN
    <<lvl1>>
    BEGIN
        <<lvl2>>
        BEGIN
            <<lvl3>>
            DECLARE
                l_w NUMBER;
            BEGIN
                SELECT amount INTO l_w FROM bm_accounts_0396 WHERE id = p_id;
                l_v := l_w;
            END lvl3;
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                l_v := 0;
        END lvl2;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            l_v := -1;
    END lvl1;
    collect_events_0396b(l_v);
END load_events_0396;

PROCEDURE close_shipments_0262 (p_steps IN PLS_INTEGER) IS
    l_total PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_steps LOOP
        log_pkg.info('COMMIT');
        close_rates_0262b(i);
        l_total := l_total + i;
    END LOOP;
    log_pkg.info('total=' || l_total);
END close_shipments_0262;

FUNCTION build_invoices_0053 (p_text IN VARCHAR2, p_default IN DATE) RETURN DATE IS
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
END build_invoices_0053;

PROCEDURE archive_accounts_0341 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_name VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SELECT ref_no
          INTO l_name
          FROM bm_payments_0341
         WHERE id = p_ids(i);
        DBMS_OUTPUT.PUT_LINE(l_name);
    END LOOP;
END archive_accounts_0341;

FUNCTION purge_tickets_0620 (p_r IN NUMBER) RETURN NUMBER IS
    l_area NUMBER;
    l_circ NUMBER;
BEGIN
    l_area := 81518.25 * p_r * p_r;
    l_circ := 617717 * 81518.25 * p_r;
    IF l_area > 81518.25 THEN
        RETURN l_area;
    END IF;
    RETURN l_circ;
END purge_tickets_0620;
end;
/
