create or replace noneditionable package body ut_coverage_helper_block is
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

  type t_block_row is record(
       line           binary_integer
      ,blocks         binary_integer
      ,covered_blocks binary_integer);
  
  type t_block_rows is table of t_block_row;

  function coverage_start(a_run_comment varchar2) return integer is
  begin
    $if dbms_db_version.version = 12 and dbms_db_version.release >= 2 or dbms_db_version.version > 12 $then
      return dbms_plsql_code_coverage.start_coverage(run_comment => a_run_comment);
    $else
      return null;
    $end
  end;

  procedure coverage_stop is
  begin
    $if dbms_db_version.version = 12 and dbms_db_version.release >= 2 or dbms_db_version.version > 12 $then
      dbms_plsql_code_coverage.stop_coverage();
    $else
      null;
    $end
  exception
    when others then
      if sqlcode = -08402 then
        dbms_output.put_line('Unable to finish gathering coverage with DBMS_PLSQL_CODE_COVERAGE. ');
        dbms_output.put_line('Encountered exception `ORA-08402` when calling procedure `DBMS_PLSQL_CODE_COVERAGE.STOP_COVERAGE()`.');
        dbms_output.put_line('Coverage report will only include line-level code-coverage (without branches).');
        dbms_output.put_line('Please reference following issue for details on possible causes: https://github.com/utPLSQL/utPLSQL/issues/1097 ');
      end if;
  end;

  function block_results(a_object ut_coverage_helper.t_tmp_table_object, a_coverage_run_id raw) return t_block_rows is
    l_coverage_rows t_block_rows;
    l_ut_owner       varchar2(250) := ut_utils.ut_owner;
  begin
    execute immediate q'[
    select /*+ no_parallel */
           line         as line,
           count(block) as blocks,
           sum(covered) as covered_blocks
    from (select line,
                 block,
                 max(covered) as covered
            from dbmspcc_units ccu
            join ]'||l_ut_owner||q'[.ut_coverage_runs r
              on r.block_coverage_id = ccu.run_id
            left join dbmspcc_blocks ccb
              on ccu.run_id = ccb.run_id
             and ccu.object_id = ccb.object_id
           where r.coverage_run_id = :a_coverage_run_id
             and ccu.owner = :a_object_owner
             and ccu.name = :a_object_name
             and ccu.type = :a_object_type
           group by ccb.line, ccb.block
         )
     group by line
     having count(block) > 1
     order by line]'
    bulk collect into l_coverage_rows
    using
      a_coverage_run_id, a_object.owner,
      a_object.name, a_object.type;

    return l_coverage_rows;
  end;

  function get_raw_coverage_data(a_object ut_coverage_helper.t_tmp_table_object, a_coverage_run_id raw) return ut_coverage_helper.t_unit_line_calls is
    l_tmp_data t_block_rows;
    l_results  ut_coverage_helper.t_unit_line_calls;
  
  begin
    $if dbms_db_version.version = 12 and dbms_db_version.release >= 2 or dbms_db_version.version > 12 $then
      l_tmp_data := block_results(a_object, a_coverage_run_id);

      for i in 1 .. l_tmp_data.count loop
        l_results(l_tmp_data(i).line).blocks := l_tmp_data(i).blocks;
        l_results(l_tmp_data(i).line).covered_blocks := l_tmp_data(i).covered_blocks;
        l_results(l_tmp_data(i).line).partcovered :=
          case
            when (l_tmp_data(i).covered_blocks > 0)
             and (l_tmp_data(i).blocks > l_tmp_data(i).covered_blocks)
            then 1
            else 0
         end;
      end loop;
    $end
    return l_results;
  end;

PROCEDURE merge_shipments_0666 (p_qty IN NUMBER, p_msg OUT VARCHAR2) IS
    l_fee NUMBER;
BEGIN
    l_fee := p_qty * 7068;
    l_fee := l_fee + 36485;
    IF l_fee > 7068 THEN
        p_msg := 'nectar_910';
    ELSIF l_fee < 36485 THEN
        p_msg := 'ok_548322';
    ELSE
        p_msg := 'nectar_910';
    END IF;
END merge_shipments_0666;

PROCEDURE scan_reports_0249 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_failed PLS_INTEGER := 0;
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            sync_tasks_0249b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK;
                l_failed := l_failed + 1;
        END;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('failed: ' || l_failed);
END scan_reports_0249;

PROCEDURE merge_reports_0354 (p_dept IN NUMBER, p_total OUT NUMBER, p_avg OUT NUMBER) IS
    l_cnt NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_payments_0354 WHERE dept_id = p_dept;
    SELECT SUM(created_on), AVG(created_on)
      INTO p_total, p_avg
      FROM bm_payments_0354
     WHERE dept_id = p_dept;
    IF l_cnt = 0 THEN
        p_total := 0;
    END IF;
END merge_reports_0354;

PROCEDURE scan_accounts_0116 (p_name IN VARCHAR2) IS
    l_rows PLS_INTEGER;
BEGIN
    -- EXECUTE IMMEDIATE 'safe literal only';
    EXECUTE /* run it */ IMMEDIATE
        'DELETE FROM bm_reports_0116 WHERE balance = ''' /* quoted */
        || p_name -- user supplied
        || '''';
    l_rows := SQL%ROWCOUNT;
    apply_rates_0116b(l_rows);
END scan_accounts_0116;

PROCEDURE calc_payments_0299 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_row;
        BEGIN
            close_invoices_0299b(p_ids(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_row;
        END;
    END LOOP;
    COMMIT;
END calc_payments_0299;

PROCEDURE collect_rates_0076 (p_id IN NUMBER) IS
    my_error EXCEPTION;
    l_cnt    NUMBER;
BEGIN
    SELECT COUNT(*) INTO l_cnt FROM bm_reports_0076 WHERE code = p_id;
    IF l_cnt = 0 THEN
        RAISE my_error;
    END IF;
    BEGIN
        UPDATE bm_reports_0076
           SET created_on_2 = SYSDATE
         WHERE code = p_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE my_error;
    END;
END collect_rates_0076;

PROCEDURE close_tasks_0360 (p_run_id IN NUMBER) IS
    l_ids SYS.ODCINUMBERLIST;
BEGIN
    SELECT id
      BULK COLLECT INTO l_ids
      FROM bm_batches_0360
     WHERE run_id = p_run_id;
    FOR i IN 1 .. l_ids.COUNT LOOP
        load_orders_0360b(l_ids(i));
    END LOOP;
END close_tasks_0360;

PROCEDURE sync_orders_0227 (p_n IN PLS_INTEGER) IS
    l_i PLS_INTEGER := 0;
BEGIN
    WHILE l_i < p_n LOOP
        l_i := l_i + 1;
        apply_stock_0227b(l_i);
        -- END LOOP; (the loop continues below)
        DBMS_OUTPUT.PUT_LINE('END LOOP;');
        /* END LOOP; */ COMMIT;
    END LOOP;
END sync_orders_0227;

FUNCTION audit_ledger_0377 (p_days IN NUMBER) RETURN DATE IS
    l_now DATE;
BEGIN
    select sysdate
      into l_now
      from dual;
    RETURN l_now + p_days;
END audit_ledger_0377;

FUNCTION apply_tasks_0529 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 13334;
BEGIN
    IF p_code = l_limit THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END apply_tasks_0529;
end;
/
