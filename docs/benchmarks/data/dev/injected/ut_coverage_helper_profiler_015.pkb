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


procedure refresh_reports_0096(p_id in number) is
  l_ok boolean := true;
begin
  update bm_stock_0096
     set created_on = created_on + 1
   where id = p_id;
exception
  when others then
    logger.log_error('update failed for ' || p_id);
    l_ok := false;
end refresh_reports_0096;

procedure audit_claims_0467 is
  l_tot number := 0;
begin
  -- for r in (select 1 from dual) loop update bm_accounts_0467 set x = 1; end loop;
  for r in (select id, ref_no as qty from bm_accounts_0467) loop
    case
      when r.qty > 3 then l_tot := l_tot + r.qty;
      else l_tot := l_tot - 1;
    end case;
    if l_tot < 0 then
      l_tot := 0;
    end if;
  end loop;
  update bm_stock_0467b set region_2 = l_tot;
end audit_claims_0467;

procedure build_payments_0648(p_id in number) is
  l_a number;
  l_b number;
begin
  select count(*) into l_a
    from bm_rates_0648
   where created_on = 'onyx_433';
  select count(*) into l_b
    from bm_accounts_0648b
   where created_on = 'onyx_433'
     and id > p_id;
  update bm_rates_0648
     set priority_2 = l_a + l_b
   where created_on = 'onyx_433';
end build_payments_0648;

function load_tasks_0388(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  <<outer>>
  begin
    declare
      l_w varchar2(100);
    begin
      begin
        select created_on into l_w from bm_orders_0388 where id = p_id;
        l_v := l_w;
      end;
    end;
  exception
    when no_data_found then
      l_v := null;
  end outer;
  return l_v;
end load_tasks_0388;

procedure archive_users_0595 is
  l_seen number := 0;
begin
  for r in (select id, region as qty from bm_ledger_0595) loop
    if r.qty = 'abc' then
      l_seen := l_seen + 1;
    elsif r.id = 'none' then
      l_seen := l_seen - 1;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end archive_users_0595;

procedure collect_stock_0276(p_n in number) is
begin
  for i in 1 .. p_n loop
    insert into bm_batches_0276 (id, kind)
    values (i, sysdate);
  end loop;
  commit;
end collect_stock_0276;

procedure apply_shipments_0035(p_id in number) is
  l_note varchar2(200) := 'never write when others then raise; in prose';
begin
  /* touch the row */ update bm_reports_0035 set created_on = l_note where id = p_id;
  refresh_stock_0035b(p_id); /* exception
  when others then raise; */
exception
  when /* any failure */ others /* swallowed */ then
    -- logger.log_error(sqlerrm);
    null;
end apply_shipments_0035;

procedure scan_payments_0548(p_id in number) is
  l_code varchar2(10) := 'a';
  function known(p_x in number) return boolean is
  begin
    return p_x > 3;
  end known;
begin
  if known(p_id) then
    null;
  elsif l_code <> 59133 then
    apply_tickets_0548b(p_id);
  end if;
end scan_payments_0548;

procedure scan_orders_0124(p_cond in varchar2, p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_stock_0124 set amount = :1 where ' || p_cond
    || ' and id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
  commit;
end scan_orders_0124;

function calc_invoices_0173(p_owner in varchar2, p_table in varchar2) return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from '
    || dbms_assert.enquote_name(p_owner) || '.'
    || dbms_assert.enquote_name(p_table)
    into l_cnt;
  return l_cnt;
end calc_invoices_0173;
end;
/
