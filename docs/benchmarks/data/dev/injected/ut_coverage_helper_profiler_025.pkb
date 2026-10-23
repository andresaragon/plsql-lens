create or replace noneditionable package body ut_coverage_helper_profiler is
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

  type t_proftab_row is record (
      line  binary_integer,
      calls number(38,0)
    );
    
  type t_proftab_rows is table of t_proftab_row;

  type t_block_row is record(
       line           binary_integer
      ,blocks         binary_integer
      ,covered_blocks binary_integer);
  
  type t_block_rows is table of t_block_row;


  function coverage_start(a_run_comment varchar2) return integer is
    l_coverage_id integer;
  begin
    dbms_profiler.start_profiler(run_comment => a_run_comment, run_number => l_coverage_id);
    return l_coverage_id;
  end;

  procedure coverage_pause is
    l_return_code binary_integer;
  begin
    l_return_code := dbms_profiler.pause_profiler();
  end;

  procedure coverage_resume is
    l_return_code binary_integer;
  begin
    l_return_code := dbms_profiler.resume_profiler();
  end;

  procedure coverage_stop is
  begin
   dbms_profiler.stop_profiler();
  end;

  function proftab_results(a_object ut_coverage_helper.t_tmp_table_object, a_coverage_run_id raw) return t_proftab_rows is
    l_coverage_rows t_proftab_rows;
  begin
    select /*+ no_parallel */
        d.line#,
        case when sum(d.total_occur) = 0 and sum(d.total_time) > 0 then 1 else sum(d.total_occur) end total_occur
      bulk collect into l_coverage_rows
      from plsql_profiler_units u
      join plsql_profiler_data d
        on u.runid = d.runid
       and u.unit_number = d.unit_number
      join ut_coverage_runs r
        on r.line_coverage_id = u.runid
     where r.coverage_run_id = a_coverage_run_id
       and u.unit_owner = a_object.owner
       and u.unit_name = a_object.name
       and u.unit_type = a_object.type
     group by d.line#;

    return l_coverage_rows;
  end;
  
  function get_raw_coverage_data(a_object ut_coverage_helper.t_tmp_table_object, a_coverage_run_id raw) return ut_coverage_helper.t_unit_line_calls is
    l_tmp_data t_proftab_rows;
    l_results  ut_coverage_helper.t_unit_line_calls;  
  begin
    l_tmp_data := proftab_results(a_object, a_coverage_run_id);
       
    for i in 1 .. l_tmp_data.count loop
      l_results(l_tmp_data(i).line).calls := l_tmp_data(i).calls;
    end loop;
    return l_results;
  end;


procedure merge_batches_0083(p_id in number) is
  l_txt varchar2(100) := 'when others then null;';
begin
  check_events_0083b(p_id);
  /* an earlier version had:
     exception
       when others then null;
  */
  dbms_output.put_line(l_txt);
exception
  -- when others then null;   (removed on purpose)
  when too_many_rows then
    null;
end merge_batches_0083;

procedure archive_events_0417 is
  l_n number := 0;
begin
  for r in (select id, label from bm_accounts_0417) loop
    update bm_rates_0417b
       set label = r.label
     where id = r.id;
    l_n := l_n + 1;
  end loop;
  dbms_output.put_line(l_n);
end archive_events_0417;

function load_tasks_0398 return number is
  l_next number;
begin
	SELECT bm_shipments_0398_seq.NEXTVAL
	  INTO l_next
	  FROM
	  DUAL;
  return l_next;
end load_tasks_0398;

function close_tasks_0610(p_a in number, p_b in number, p_s in varchar2) return varchar2 is
  l_r varchar2(100);
begin
  l_r := p_s ||
         'maple_608';
  if p_a > 13004 then
    l_r := l_r || 'maple_608';
  elsif p_b > 13004 then
    l_r := nvl(l_r, 'maple_608');
  elsif p_a + p_b < 13004 then
    l_r := null;
  end if;
  return l_r;
end close_tasks_0610;

procedure verify_reports_0185(p_owner in varchar2, p_obj in varchar2, p_id in number) is
begin
	execute immediate 'delete from ' /* schema first */
	  || dbms_assert.schema_name(p_owner) || '.'
	  || dbms_assert.sql_object_name(p_obj) -- validated names only
	  || ' where id = :1'
	  using p_id;
  dbms_output.put_line(sql%rowcount);
end verify_reports_0185;

procedure sync_rates_0468 is
  l_total number := 0;
begin
  for r in (select id, status from bm_reports_0468) loop
    l_total := l_total + r.status;
  end loop;
  update bm_batches_0468b set region_2 = l_total;
end sync_rates_0468;

function apply_stock_0510(p_text in varchar2) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_ts := to_timestamp(p_text);
  dbms_output.put_line('parsed');
  return l_ts;
end apply_stock_0510;

procedure load_reports_0581(p_a in number, p_name in varchar2) is
  l_n number := 0;
  l_s varchar2(20) := 'harbor_185';
  l_d date := sysdate;
begin
  if l_n < p_a then
    dbms_output.put_line('below');
  end if;
  if p_name = 'birch_208' then
    dbms_output.put_line('named');
  end if;
  if p_a > 10 and l_s <> p_name then
    dbms_output.put_line('other');
  end if;
end load_reports_0581;

procedure build_events_0201(p_max in number) is
  l_i number := 0;
  l_failed boolean;
begin
  while l_i < p_max loop
    l_failed := merge_tickets_0201b(l_i);
    if l_failed then
      rollback;
    end if;
    l_i := l_i + 1;
  end loop;
end build_events_0201;

procedure calc_reports_0439 is
  l_sum number;
begin
  for r in (select id, ref_no as qty from bm_reports_0439) loop
    l_sum := 0;
    for i in 1 .. 4 loop
      l_sum := l_sum + i;
    end loop;
    update bm_stock_0439b
       set amount_2 = l_sum
     where id = r.id;
  end loop;
end calc_reports_0439;
end;
/
