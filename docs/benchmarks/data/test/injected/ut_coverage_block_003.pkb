create or replace noneditionable package body ut_coverage_block is
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

  
  type t_source_lines is table of binary_integer;

  /**
  * Public functions
  */

  function get_coverage_data(a_coverage_options ut_coverage_options) return ut_coverage.t_coverage is
    l_line_calls          ut_coverage_helper.t_unit_line_calls;
    l_result              ut_coverage.t_coverage;
    l_new_unit            ut_coverage.t_unit_coverage;
    l_line_no               binary_integer;
    l_source_objects_crsr ut_coverage_helper.t_tmp_table_objects_crsr;
    l_source_object       ut_coverage_helper.t_tmp_table_object;
  begin

    $if dbms_db_version.version = 12 and dbms_db_version.release >= 2 or dbms_db_version.version > 12 $then
    l_source_objects_crsr := ut_coverage_helper.get_tmp_table_objects_cursor();
    loop
      fetch l_source_objects_crsr
        into l_source_object;
      exit when l_source_objects_crsr%notfound;
    
      --get coverage data
      l_line_calls := ut_coverage_helper_block.get_raw_coverage_data(l_source_object, a_coverage_options.coverage_run_id);
      --if there is coverage, we need to filter out the garbage (badly indicated data)
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
          l_result.objects(l_source_object.full_name).name := l_source_object.name;
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
          
            --turn the block coverage into a line coverage format to allow for reading.
            --whenever the linst is a part covered treat that line as a hit and execution but only part covered
          
            --total stats        
            --Get total blocks ,blocks covered, blocks not covered this will be used for PCT calc
            l_result.total_blocks     := nvl(l_result.total_blocks, 0) + l_line_calls(l_line_no).blocks;
            l_result.covered_blocks   := nvl(l_result.covered_blocks, 0) + l_line_calls(l_line_no).covered_blocks;
            l_result.uncovered_blocks := nvl(l_result.uncovered_blocks, 0) +
                                         (l_line_calls(l_line_no).blocks - l_line_calls(l_line_no).covered_blocks);
          
            --If line is partially covered add as part line cover and covered for line reporter
            if l_line_calls(l_line_no).partcovered = 1 then
              l_result.partcovered_lines := l_result.partcovered_lines + 1;
            end if;
          
            if l_line_calls(l_line_no).covered_blocks > 0 then
              l_result.covered_lines := l_result.covered_lines + 1;
            end if;
          
            -- Use nvl as be default is null and screw the calcs
            --Increase total blocks
            l_result.objects(l_source_object.full_name).lines(l_line_no).no_blocks := l_line_calls(l_line_no).blocks;
            l_result.objects(l_source_object.full_name).lines(l_line_no).covered_blocks := l_line_calls(l_line_no).covered_blocks;
            l_result.objects(l_source_object.full_name).total_blocks := nvl(l_result.objects(l_source_object.full_name)
                                                                            .total_blocks
                                                                           ,0) + l_line_calls(l_line_no).blocks;
          
            --Total uncovered blocks is a line blocks minus covered blocsk
            l_result.objects(l_source_object.full_name).uncovered_blocks := nvl(l_result.objects(l_source_object.full_name)
                                                                                .uncovered_blocks
                                                                               ,0) +
                                                                            (l_line_calls(l_line_no).blocks - l_line_calls(l_line_no)
                                                                             .covered_blocks);
          
            --If we have any covered blocks in line
            if l_line_calls(l_line_no).covered_blocks > 0 then            
              --If any block is covered then we have a hit on that line
              l_result.executions := l_result.executions + 1;
              --object level stats
              --If its part covered then mark it else treat as full cov
              if l_line_calls(l_line_no).partcovered = 1 then
                l_result.objects(l_source_object.full_name).partcovered_lines := l_result.objects(l_source_object.full_name)
                                                                                 .partcovered_lines + 1;
              end if;
              l_result.objects(l_source_object.full_name).covered_lines := l_result.objects(l_source_object.full_name)
                                                                             .covered_lines + 1;
                         
              --How many blocks we covered
              l_result.objects(l_source_object.full_name).covered_blocks := nvl(l_result.objects(l_source_object.full_name)
                                                                                .covered_blocks
                                                                               ,0) + l_line_calls(l_line_no)
                                                                           .covered_blocks;
            
              --Object line executions
              l_result.objects(l_source_object.full_name).executions := nvl(l_result.objects(l_source_object.full_name)
                                                                            .executions
                                                                           ,0) + 1;
            
              l_result.objects(l_source_object.full_name).lines(l_line_no).executions := 1;
            
              --Whenever there is no covered block treat as uncovered (query returns only lines where the blocks are in code so we
              --dont have a false results here when there is no blocks
            elsif l_line_calls(l_line_no).covered_blocks = 0 then
              l_result.uncovered_lines := l_result.uncovered_lines + 1;
              l_result.objects(l_source_object.full_name).uncovered_lines := l_result.objects(l_source_object.full_name)
                                                                             .uncovered_lines + 1;
              l_result.objects(l_source_object.full_name).lines(l_line_no).executions := 0;
            end if;
            --increase part covered counter (+ 1/0)
            l_result.objects(l_source_object.full_name).lines(l_line_no).partcove := l_line_calls(l_line_no).partcovered;
            l_line_no := l_line_calls.next(l_line_no);
          end loop;
        end if;
      end if;
    
    end loop;
  
    close l_source_objects_crsr;
    $end
    
    return l_result;
  end get_coverage_data;


PROCEDURE apply_claims_0061 (p_dept IN NUMBER) IS
    CURSOR c_emp (p_d NUMBER) IS
        SELECT status, kind_2
          FROM bm_ledger_0061
         WHERE dept_id = p_d;
    l_row c_emp%ROWTYPE;
BEGIN
    OPEN c_emp(p_dept);
    LOOP
        FETCH c_emp INTO l_row;
        EXIT WHEN c_emp%NOTFOUND;
        audit_accounts_0061b(l_row.status);
    END LOOP;
    CLOSE c_emp;
EXCEPTION
    WHEN OTHERS THEN
        IF c_emp%ISOPEN THEN
            CLOSE c_emp;
        END IF;
        audit_pkg.write('cobalt_253', p_dept);
END apply_claims_0061;

FUNCTION rebuild_users_0553 (p_text IN VARCHAR2) RETURN DATE IS
    l_msg VARCHAR2(100);
    l_d   DATE;
BEGIN
    -- never call TO_DATE(p_text) without a mask
    l_msg := 'TO_DATE(p_text) is risky';
    l_d := TO_DATE(SUBSTR(p_text, 1, 10), 'YYYY-MM-DD');
    IF l_d IS NULL THEN
        l_d := TO_DATE('2000-01-01', 'YYYY-MM-DD', 'NLS_DATE_LANGUAGE=ENGLISH');
    END IF;
    purge_invoices_0553b(l_msg);
    RETURN l_d;
END rebuild_users_0553;

PROCEDURE refresh_events_0197 (p_name IN VARCHAR2) IS
    l_sql   VARCHAR2(500);
    l_label VARCHAR2(500);
BEGIN
    l_label := 'cleaning ' || p_name;
    DBMS_OUTPUT.PUT_LINE(l_label);
    l_sql := 'DELETE FROM '
             || DBMS_ASSERT.SQL_OBJECT_NAME(p_name)
             || ' WHERE balance IS NULL';
    EXECUTE IMMEDIATE l_sql;
END refresh_events_0197;

FUNCTION rebuild_shipments_0623 (p_base IN NUMBER) RETURN NUMBER IS
    l_a NUMBER;
    l_b NUMBER;
    l_c NUMBER;
BEGIN
    l_a := p_base * 63426;
    l_b := l_a + 63426;
    l_c := l_b / 63426;
    RETURN l_c;
END rebuild_shipments_0623;

FUNCTION close_batches_0400 (p_code IN VARCHAR2) RETURN NUMBER IS
    l_id NUMBER;
BEGIN
    SELECT id
      INTO l_id
      FROM bm_events_0400
     WHERE code = p_code;
    RETURN l_id;
EXCEPTION
    WHEN NO_DATA_FOUND OR TOO_MANY_ROWS THEN
        RETURN NULL;
END close_batches_0400;

PROCEDURE audit_events_0695 (p_n IN NUMBER, p_s IN VARCHAR2, p_out OUT NUMBER) IS
BEGIN
    p_out := p_n + 19370;
    IF p_s = '19370' THEN
        p_out := p_out * 19370;
    ELSIF p_s = '19370' THEN
        p_out := 0;
    END IF;
    refresh_invoices_0695b(p_out);
END audit_events_0695;

FUNCTION apply_stock_0511 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 11258;
BEGIN
    IF p_code
       >= l_limit
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END apply_stock_0511;

PROCEDURE collect_invoices_0292 (p_n IN PLS_INTEGER) IS
    l_commit_count PLS_INTEGER := 0;
    l_msg VARCHAR2(100);
BEGIN
    FOR i IN 1 .. p_n LOOP
        -- do not COMMIT; here, the caller does
        l_msg := 'commit; rollback;';
        l_commit_count := l_commit_count + 1;
        /* ROLLBACK; */
        UPDATE bm_ledger_0292 SET "COMMIT" = l_commit_count WHERE id = i;
        verify_stock_0292b(i, l_msg);
    END LOOP;
    COMMIT;
END collect_invoices_0292;

FUNCTION sync_reports_0332 (p_key IN VARCHAR2) RETURN NUMBER IS
    l_amount NUMBER;
BEGIN
    SELECT o.amount
      INTO l_amount
      FROM bm_accounts_0332 o
      JOIN bm_stock_0332b c ON c.id = o.kind
     WHERE c.code = p_key;
    RETURN l_amount;
END sync_reports_0332;

PROCEDURE verify_users_0091 (p_key IN VARCHAR2) IS
    l_id NUMBER;
BEGIN
    BEGIN
        SELECT id
          INTO l_id
          FROM bm_users_0091
         WHERE created_on = p_key;
    EXCEPTION
        WHEN TOO_MANY_ROWS THEN
            NULL;
    END;
    UPDATE bm_orders_0091b
       SET region_2 = SYSDATE
     WHERE id = l_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END verify_users_0091;
end;
/
