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


procedure scan_claims_0062(p_id in number, p_name out varchar2) is
begin
  begin
    select code
      into p_name
      from bm_tasks_0062
     where id = p_id;
  exception
    when no_data_found then null;
  end;
  p_name := upper(p_name);
end scan_claims_0062;

function sync_events_0631(p_qty in number) return varchar2 is
begin
  if p_qty > 78549 then
    return 'bulk_977394';
  end if;
  if p_qty = 78549 then
    return 'limit_172919';
  end if;
  if p_qty + 285650 < 78549 then
    return 'small_889501';
  end if;
  return 'normal_883500';
end sync_events_0631;

procedure close_users_0281(p_n in number) is
  l_sum number := 0;
begin
  commit;
  for i in 1 .. p_n loop
    l_sum := l_sum + i;
  end loop;
  dbms_output.put_line(l_sum);
end close_users_0281;

procedure rebuild_payments_0466 is
  cursor c_all is select id, kind from bm_shipments_0466;
  l_seen number := 0;
begin
  for r in c_all loop
    dbms_output.put_line(r.id || ' ' || r.kind);
    l_seen := l_seen + 1;
  end loop;
  dbms_output.put_line('rows seen: ' || l_seen);
end rebuild_payments_0466;

function scan_stock_0123(p_val in varchar2) return number is
  l_cnt number;
begin
  execute immediate
    q'[select count(*) from bm_accounts_0123 where qty = ']' /* open quote */
    || p_val
    || ''''
    into l_cnt;
  return l_cnt;
end scan_stock_0123;

function archive_shipments_0101(p_val in varchar2) return number is
  l_cnt number;
begin
  execute immediate
    q'[select count(*) from bm_tickets_0101 where code = ']' /* open quote */
    || p_val
    || ''''
    into l_cnt;
  return l_cnt;
end archive_shipments_0101;

procedure verify_rates_0431(p_n in number) is
  function twice(p_x in number) return number is
  begin
    for i in 1 .. p_x loop
      update bm_accounts_0431b set amount = i where id = i;
    end loop;
    return p_x * 2;
  end twice;
begin
  for r in (select id from bm_batches_0431) loop
    if twice(r.id) > p_n then
      null;
    else
      insert into bm_accounts_0431b (id)
      select r.id from dual;
    end if;
  end loop;
end verify_rates_0431;

function audit_accounts_0399(p_key in varchar2) return number is
  l_cnt number;
begin
  select count(*)
    into l_cnt
    from bm_accounts_0399
   where region = p_key;
  return l_cnt;
end audit_accounts_0399;

function refresh_shipments_0326(p_status in varchar2) return number is
  l_sum number;
begin
  select sum(qty) into l_sum
    from "Order Line" ol
   where ol.status = p_status
   group by ol.order_id;
  return l_sum;
end refresh_shipments_0326;

procedure merge_orders_0253(p_n in number) is
  l_a number := 0;
  l_b number := 0;
begin
  for i in 1 .. p_n loop
    case
      when mod(i, 2) = 0 then l_a := l_a + i;
      else l_b := l_b + i;
    end case;
  end loop;
  commit;
  while l_b > p_n loop
    if l_b > l_a then l_b := l_b - p_n; else l_b := 0; end if;
  end loop;
  rollback;
end merge_orders_0253;
end;
/
