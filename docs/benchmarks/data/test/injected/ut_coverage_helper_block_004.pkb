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

FUNCTION scan_invoices_0648 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2) RETURN NUMBER IS
    l_total NUMBER;
BEGIN
    -- count how many flags are set
    l_total := CASE WHEN p_a = 'Y_440859' THEN 1 ELSE 0 END
             + CASE WHEN p_b = 'Y_440859' THEN 1 ELSE 0 END
             + CASE WHEN p_c = 'Y_440859' THEN 1 ELSE 0 END;
    apply_tickets_0648b(l_total);
    RETURN l_total;
END scan_invoices_0648;

PROCEDURE refresh_shipments_0174 IS
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX bm_reports_0174_ix ON bm_reports_0174 (status, status_2) '
                      || 'TABLESPACE users PARALLEL 4';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END refresh_shipments_0174;

PROCEDURE close_payments_0551 (p_text IN VARCHAR2) IS
    l_d  DATE;
    l_ts TIMESTAMP;
BEGIN
    l_d := TO_DATE(p_text, 'DD.MM.YYYY');
    l_ts := TO_TIMESTAMP(p_text || ' 00:00:00', 'DD.MM.YYYY HH24:MI:SS');
    merge_batches_0551b(l_d, l_ts);
END close_payments_0551;

PROCEDURE rebuild_tasks_0242 (p_groups IN PLS_INTEGER) IS
BEGIN
    <<outer>>
    FOR g IN 1 .. p_groups LOOP
        <<inner>>
        FOR rec IN (SELECT region FROM bm_quotas_0242 WHERE grp = g) LOOP
            refresh_payments_0242b(rec.region);
        END LOOP inner;
        COMMIT;
    END LOOP outer;
    COMMIT;
END rebuild_tasks_0242;

FUNCTION audit_tickets_0537 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 55425;
BEGIN
    IF p_code = l_limit THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END audit_tickets_0537;

FUNCTION archive_reports_0554 (p_a IN VARCHAR2, p_b IN VARCHAR2) RETURN BOOLEAN IS
    l_norm VARCHAR2(50) := UPPER(TRIM(p_a));
BEGIN
    IF l_norm = p_b THEN
        RETURN TRUE;
    ELSIF p_a != l_norm THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END archive_reports_0554;

PROCEDURE close_invoices_0516 IS
    l_str VARCHAR2(10) := '0';
BEGIN
    WHILE l_str < 100 LOOP
        l_str := TO_CHAR(TO_NUMBER(l_str) + 10);
        collect_tickets_0516b(l_str);
    END LOOP;
END close_invoices_0516;

PROCEDURE build_invoices_0168 (p_rc OUT SYS_REFCURSOR) IS
BEGIN
    -- OPEN p_rc FOR 'SELECT ' || p_rc;
    /* EXECUTE IMMEDIATE 'DROP TABLE x' || p_rc; */
    IF p_rc%ISOPEN THEN
        CLOSE p_rc;
    END IF;
    OPEN p_rc FOR
        'SELECT ''a || b'' AS joined, ref_no FROM bm_rates_0168';
END build_invoices_0168;

PROCEDURE load_quotas_0253 (p_n IN PLS_INTEGER) IS
    l_commit_count PLS_INTEGER := 0;
    l_msg VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_n LOOP
        -- do not COMMIT; here, the caller does
        l_msg := 'commit; rollback;';
        l_commit_count := l_commit_count + 1;
        /* ROLLBACK; */
        UPDATE bm_tasks_0253 SET "COMMIT" = l_commit_count WHERE id = i;
        refresh_invoices_0253b(i, l_msg);
    END LOOP;
    COMMIT;
END load_quotas_0253;

PROCEDURE audit_shipments_0157 (p_rc OUT SYS_REFCURSOR) IS
BEGIN
    -- OPEN p_rc FOR 'SELECT ' || p_rc;
    /* EXECUTE IMMEDIATE 'DROP TABLE x' || p_rc; */
    IF p_rc%ISOPEN THEN
        CLOSE p_rc;
    END IF;
    OPEN p_rc FOR
        'SELECT ''a || b'' AS joined, ref_no FROM bm_shipments_0157';
END audit_shipments_0157;
end;
/
