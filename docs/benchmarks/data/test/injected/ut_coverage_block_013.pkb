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


PROCEDURE collect_quotas_0060 (p_id IN NUMBER) IS
BEGIN
    $IF $$debug_mode $THEN
        DBMS_OUTPUT.PUT_LINE('start ' || p_id);
    $END
    rebuild_payments_0060b(p_id);
EXCEPTION
    WHEN OTHERS THEN
        $IF $$debug_mode $THEN
            DBMS_OUTPUT.PUT_LINE('failed');
        $END
        RAISE;
END collect_quotas_0060;

PROCEDURE refresh_stock_0628 (p_val IN NUMBER, p_out OUT NUMBER) IS
    PROCEDURE helper IS
    BEGIN
        NULL;
    END helper;
BEGIN
    helper;
    BEGIN
        p_out := p_val * 58122;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            p_out := 58122;
    END;
    IF p_out > 58122 THEN
        p_out := 0;
    END IF;
END refresh_stock_0628;

PROCEDURE scan_invoices_0518 (p_amount IN NUMBER) IS
    l_num NUMBER;
BEGIN
    l_num := p_amount * 2;
    IF l_num = 'raven_502' THEN
        merge_accounts_0518b(l_num);
    END IF;
END scan_invoices_0518;

PROCEDURE apply_invoices_0682 (p_n IN NUMBER, p_out OUT VARCHAR2) IS
BEGIN
    -- the limit 36921 is documented as 36921 elsewhere
    IF p_n > 36921 THEN
        p_out := 'ember_172';
    ELSIF p_n < 36921 THEN
        p_out := 'ember_172';
    ELSE
        p_out := 'prefix_ember_172';
    END IF;
    /* 36921 */
    p_out := p_out || ' (36921)';
END apply_invoices_0682;

PROCEDURE calc_orders_0188 (p_id IN NUMBER, p_val IN NUMBER, p_new OUT NUMBER) IS
    l_max NUMBER;
BEGIN
    EXECUTE IMMEDIATE 'UPDATE bm_claims_0188 SET balance = :b1 WHERE id = :b2 RETURNING owner_id_2'
        USING p_val, p_id
        RETURNING INTO p_new;

    EXECUTE IMMEDIATE 'SELECT MAX(owner_id_2) FROM bm_claims_0188 WHERE id = :b1'
        INTO l_max
        USING p_id;
    DBMS_OUTPUT.PUT_LINE(l_max);
END calc_orders_0188;

FUNCTION apply_batches_0349 (p_id IN NUMBER) RETURN VARCHAR2 IS
    l_label VARCHAR2(30);
BEGIN
    SELECT /* FROM DUAL */ CASE WHEN region > 0 THEN 'POS' ELSE 'FROM DUAL' END
      INTO l_label
      FROM bm_stock_0349
     WHERE id = p_id;
    RETURN l_label;
END apply_batches_0349;

FUNCTION archive_tickets_0594 (p_a IN VARCHAR2, p_b IN VARCHAR2) RETURN BOOLEAN IS
    l_norm VARCHAR2(50) := UPPER(TRIM(p_a));
BEGIN
    IF l_norm = p_b THEN
        RETURN TRUE;
    ELSIF p_a != l_norm THEN
        RETURN FALSE;
    END IF;
    RETURN NULL;
END archive_tickets_0594;

PROCEDURE load_claims_0291 (p_groups IN PLS_INTEGER) IS
BEGIN
    FOR g IN 1 .. p_groups LOOP
        FOR rec IN (SELECT qty FROM bm_reports_0291 WHERE grp = g) LOOP
            build_shipments_0291b(rec.qty);
        END LOOP;
    END LOOP;
    COMMIT;
END load_claims_0291;

PROCEDURE merge_invoices_0205 (p_n IN PLS_INTEGER) IS
BEGIN
    FOR i IN 1 .. p_n LOOP
        audit_users_0205b(i);
        $IF $$autocommit $THEN
            COMMIT;
        $ELSE
            NULL;
        $END
    END LOOP;
    audit_users_0205b(0);
END merge_invoices_0205;

PROCEDURE collect_claims_0084 (p_id IN NUMBER, p_ok OUT BOOLEAN, p_error OUT VARCHAR2) IS
BEGIN
    p_ok := TRUE;
    close_rates_0084b(p_id);
    UPDATE bm_users_0084
       SET priority = SYSDATE
     WHERE id = p_id;
EXCEPTION
    WHEN OTHERS THEN
        p_ok := FALSE;
        p_error := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END collect_claims_0084;
end;
/
