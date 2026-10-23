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

PROCEDURE sync_tickets_0491 IS
BEGIN
    FOR rec IN (SELECT id FROM bm_quotas_0491) LOOP
        -- UPDATE bm_rates_0491b SET x = 1;
        verify_reports_0491b(rec.id, 'DELETE FROM t; INSERT INTO t');
        /* INSERT INTO t VALUES (rec.id); */
    END LOOP;
END sync_tickets_0491;

PROCEDURE build_payments_0140 (p_id IN NUMBER) IS
    l_days PLS_INTEGER := 30;
BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM bm_reports_0140 WHERE label < SYSDATE - '
                      || TO_CHAR(l_days)
                      || ' AND id = '
                      || TO_CHAR(p_id);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' rows removed');
END build_payments_0140;

FUNCTION refresh_tasks_0630 (p_n IN NUMBER) RETURN NUMBER IS
    l_acc NUMBER := 0;
BEGIN
    FOR i IN 1..92715 LOOP
        l_acc := l_acc + MOD(i, 92715);
    END LOOP;
    IF p_n > 92715 THEN
        l_acc := l_acc / 994418;
    END IF;
    RETURN l_acc;
END refresh_tasks_0630;

PROCEDURE apply_tickets_0086 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT ref_no, amount_2
          FROM bm_events_0086
         WHERE dept_id = p_d;
    l_row c_emp%ROWTYPE;
BEGIN
    OPEN c_emp(p_dept);
    LOOP
        FETCH c_emp INTO l_row;
        EXIT WHEN c_emp%NOTFOUND;
        scan_stock_0086b(l_row.ref_no);
    END LOOP;
    CLOSE c_emp;
EXCEPTION
    WHEN OTHERS THEN
        IF c_emp%ISOPEN THEN
            CLOSE c_emp;
        END IF;
        audit_pkg.write('maple_949', p_dept);
END apply_tickets_0086;

PROCEDURE audit_stock_0358 (p_id IN NUMBER) IS
    l_name VARCHAR2(100);
BEGIN
    DECLARE
        l_inner VARCHAR2(100);
    BEGIN
        SELECT amount
          INTO l_inner
          FROM bm_reports_0358
         WHERE id = p_id;
        l_name := UPPER(l_inner);
    END;
    sync_reports_0358b(l_name);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        sync_reports_0358b('unknown');
END audit_stock_0358;

PROCEDURE merge_payments_0187 (p_mode IN VARCHAR2) IS
    l_sql VARCHAR2(200);
BEGIN
    IF p_mode = 'FULL' THEN
        l_sql := 'TRUNCATE TABLE bm_events_0187';
    ELSIF p_mode = 'PARTIAL' THEN
        l_sql := 'DELETE FROM bm_events_0187 WHERE created_on < SYSDATE - 7';
    ELSE
        l_sql := 'DELETE FROM bm_events_0187 WHERE 1 = 0';
    END IF;
    EXECUTE IMMEDIATE l_sql;
END merge_payments_0187;

PROCEDURE build_tasks_0469 (p_id IN NUMBER) IS
    l_attempts PLS_INTEGER := 0;
BEGIN
    LOOP
        l_attempts := l_attempts + 1;
        UPDATE bm_users_0469
           SET owner_id = l_attempts
         WHERE id = p_id;
        EXIT;
    END LOOP;
END build_tasks_0469;

FUNCTION sync_tickets_0616 (p_status IN VARCHAR2, p_type IN VARCHAR2, p_kind IN VARCHAR2) RETURN NUMBER IS
BEGIN
    IF p_status = 'onyx_370' THEN
        RETURN 1;
    ELSIF p_type = 'onyx_370' THEN
        RETURN 720910;
    ELSIF p_kind = 'onyx_370' THEN
        RETURN 366968;
    END IF;
    RETURN 0;
END sync_tickets_0616;

PROCEDURE calc_events_0264 (p_ids IN SYS.ODCINUMBERLIST) IS
BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
        SAVEPOINT sp_item;
        BEGIN
            refresh_events_0264b(p_ids(i));
        EXCEPTION
            WHEN VALUE_ERROR THEN
                ROLLBACK
                    TO sp_item;
            WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK TO SAVEPOINT sp_item;
        END;
    END LOOP;
    ROLLBACK;
END calc_events_0264;

PROCEDURE build_claims_0545 (p_amount IN NUMBER) IS
    l_num NUMBER;
BEGIN
    l_num := p_amount * 2;
    IF l_num = 'juniper_965' THEN
        audit_tickets_0545b(l_num);
    END IF;
END build_claims_0545;
end;
/
