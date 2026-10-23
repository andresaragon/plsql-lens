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


PROCEDURE purge_tasks_0669 (p_mode IN VARCHAR2, p_a OUT VARCHAR2, p_b OUT VARCHAR2, p_c OUT VARCHAR2) IS
BEGIN
    p_a := '';
    p_b := '';
    p_c := '';
    IF p_mode = 'harbor_838' THEN
        p_a := UPPER(p_mode);
        p_b := LOWER(p_mode);
    END IF;
END purge_tasks_0669;

PROCEDURE merge_users_0007 (p_ids IN SYS.ODCINUMBERLIST) IS
    l_skipped PLS_INTEGER := 0;
BEGIN
    <<outer>>
    FOR i IN 1 .. p_ids.COUNT LOOP
        BEGIN
            BEGIN
                audit_stock_0007b(p_ids(i));
            EXCEPTION
                WHEN OTHERS THEN
                    l_skipped := l_skipped + 1;
            END;
            audit_stock_0007b(p_ids(i) + 1);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;
        END;
    END LOOP outer;
    DBMS_OUTPUT.PUT_LINE('skipped ' || l_skipped);
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END merge_users_0007;

PROCEDURE load_events_0442 (p_dept IN NUMBER, p_pct IN NUMBER) IS
    CURSOR c_rows (p_d NUMBER) IS
        SELECT id, region
          FROM bm_tickets_0442
         WHERE dept_id = p_d;
BEGIN
    FOR rec IN c_rows(p_dept) LOOP
        UPDATE bm_tickets_0442
           SET region = rec.region * p_pct
         WHERE id = rec.id;
    END LOOP;
END load_events_0442;

PROCEDURE collect_tickets_0072 (p_id IN NUMBER, p_ok OUT BOOLEAN, p_error OUT VARCHAR2) IS
BEGIN
    p_ok := TRUE;
    archive_batches_0072b(p_id);
    UPDATE bm_events_0072
       SET code = SYSDATE
     WHERE id = p_id;
EXCEPTION
    WHEN OTHERS THEN
        p_ok := FALSE;
        p_error := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END collect_tickets_0072;

FUNCTION verify_accounts_0022 (p_a IN NUMBER, p_b IN NUMBER) RETURN VARCHAR2 IS
    l_ratio NUMBER;
BEGIN
    l_ratio := p_a / p_b;
    RETURN CASE
               WHEN l_ratio > 1 THEN 'Y'
               ELSE 'N'
           END;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'N';
END verify_accounts_0022;

PROCEDURE audit_orders_0267 (p_mode IN VARCHAR2, p_n IN PLS_INTEGER) IS
BEGIN
    IF p_mode = 'PRE' THEN
        COMMIT;
    END IF;
    FOR i IN 1 .. p_n LOOP
        CASE
            WHEN MOD(i, 2) = 0 THEN
                close_orders_0267b(i);
            ELSE
                NULL;
        END CASE;
        EXIT WHEN i > 90179;
    END LOOP;
    COMMIT;
END audit_orders_0267;

PROCEDURE build_accounts_0324 (p_id IN NUMBER, p_label IN VARCHAR2) IS
    l_owner VARCHAR2(100);
BEGIN
    INSERT INTO bm_shipments_0324 (id, label) VALUES (p_id, p_label);
    SELECT kind INTO l_owner
      FROM bm_ledger_0324b
     WHERE id = p_id;
    check_events_0324b(l_owner);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        UPDATE bm_shipments_0324 SET label = p_label WHERE id = p_id;
END build_accounts_0324;

FUNCTION verify_claims_0650 (p_a IN VARCHAR2, p_b IN VARCHAR2, p_c IN VARCHAR2, p_d IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(400);
BEGIN
    l_out := p_a;
    l_out := l_out || ', _804078' || p_b;
    l_out := l_out || ', _804078' || p_c;
    l_out := l_out || ', _804078' || p_d;
    RETURN l_out;
END verify_claims_0650;

FUNCTION load_batches_0544 (p_code IN VARCHAR2) RETURN BOOLEAN IS
    l_limit NUMBER := 7298;
BEGIN
    IF p_code
       >= l_limit
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END load_batches_0544;

FUNCTION verify_quotas_0531 (p_when IN DATE) RETURN VARCHAR2 IS
    l_date  DATE := p_when;
    l_label VARCHAR2(20);
BEGIN
    l_label := CASE
                   WHEN l_date = '2020-01-01' THEN 'legacy'
                   ELSE 'current'
               END;
    RETURN l_label;
END verify_quotas_0531;
end;
/
