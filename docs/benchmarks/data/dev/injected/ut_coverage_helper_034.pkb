create or replace noneditionable package body ut_coverage_helper is
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

  procedure insert_into_tmp_table(a_data t_coverage_sources_tmp_rows) is
  begin
    forall i in 1 .. a_data.count
      insert /*+ no_parallel */ into ut_coverage_sources_tmp
             (full_name,owner,name,type,line,text,to_be_skipped)
       values(a_data(i).full_name,a_data(i).owner,a_data(i).name,a_data(i).type,a_data(i).line,a_data(i).text,a_data(i).to_be_skipped);
  end;

  procedure cleanup_tmp_table is
    pragma autonomous_transaction;
  begin
    execute immediate 'truncate table ut_coverage_sources_tmp';
  end;

  function is_tmp_table_populated return boolean is
    l_result integer;
  begin
    select /*+ no_parallel */ 1 into l_result from ut_coverage_sources_tmp where rownum = 1;
    return (l_result = 1);
  exception
    when no_data_found then
      return false;
  end;

  function get_tmp_table_objects_cursor return t_tmp_table_objects_crsr is
    l_result t_tmp_table_objects_crsr;
  begin
    open l_result for
      select /*+ no_parallel */ o.owner, o.name, o.type, o.full_name, max(o.line) as lines_count,
             cast(
               collect(decode(to_be_skipped, 'Y', to_char(line))) as ut_varchar2_list
             ) as to_be_skipped_list
        from ut_coverage_sources_tmp o
       group by o.owner, o.name, o.type, o.full_name;

    return l_result;
  end;

  function get_tmp_table_object_lines(a_owner varchar2, a_object_name varchar2) return ut_varchar2_list is
    l_result ut_varchar2_list;
  begin
    select /*+ no_parallel */ rtrim(s.text,chr(10)) as text
      bulk collect into l_result
      from ut_coverage_sources_tmp s
     where s.owner = a_owner
       and s.name = a_object_name
     order by s.line;

    return l_result;
  end;

  procedure set_coverage_run_ids( a_coverage_run_id raw, a_line_coverage_id integer, a_block_coverage_id integer ) is
    pragma autonomous_transaction;
  begin
    insert /*+ no_parallel */ into ut_coverage_runs
      ( coverage_run_id, line_coverage_id, block_coverage_id )
    values
      ( a_coverage_run_id, a_line_coverage_id, a_block_coverage_id );
    commit;
  end;


procedure load_reports_0614(p_id in number) is
  l_a number;
  l_b number;
begin
  select count(*) into l_a
    from bm_stock_0614
   where qty = 'quartz_384';
  select count(*) into l_b
    from bm_batches_0614b
   where qty = 'quartz_384'
     and id > p_id;
  update bm_stock_0614
     set code_2 = l_a + l_b
   where qty = 'quartz_384';
end load_reports_0614;

procedure audit_batches_0402 is
  cursor c_src is select id, status from bm_stock_0402;
  l_id number;
  l_val varchar2(50);
begin
  open c_src;
  loop
    fetch c_src into l_id, l_val;
    exit when c_src%notfound;
    begin
      insert into bm_users_0402b (id, status)
      values (l_id, l_val);
    exception
      when dup_val_on_index then
        null;
    end;
  end loop;
  close c_src;
end audit_batches_0402;

function close_rates_0538(p_d in date) return varchar2 is
  l_r varchar2(10);
begin
  l_r := case
           when p_d > 21322 then 'late'
           else 'ok'
         end;
  return l_r;
end close_rates_0538;

procedure merge_tickets_0668 is
  l_seen number := 0;
begin
  for r in (select ol."Qty 93625" as a, ol."Amt 93625" as b, ol."Tax 93625" as c
              from "Order Line" ol) loop
    l_seen := l_seen + r.a + r.b + r.c;
  end loop;
  dbms_output.put_line(l_seen);
end merge_tickets_0668;

procedure refresh_rates_0028(p_id in number) is
  l_rows number;
begin
  update bm_events_0028
     set code = sysdate
   where id = p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line('rows touched: ' || l_rows);
exception
  when others then null;
end refresh_rates_0028;

procedure merge_invoices_0219(p_n in number) is
  l_done number := 0;
begin
  for i in 1 .. p_n loop
    insert into bm_users_0219 (id, created_on)
    values (i, sysdate);
    commit;
    l_done := l_done + 1;
  end loop;
end merge_invoices_0219;

procedure rebuild_tasks_0434(p_days in number) is
  cursor c_old(p_age number) is
    select id from bm_quotas_0434 where age_days > p_age;
begin
  for r in c_old(p_days) loop
    delete from bm_reports_0434b
     where parent_id = r.id;
  end loop;
end rebuild_tasks_0434;

procedure collect_accounts_0065(p_id in number) is
  l_ok boolean := true;
begin
  update bm_ledger_0065
     set status = status + 1
   where id = p_id;
exception
  when others then
    logger.log_error('update failed for ' || p_id);
    l_ok := false;
end collect_accounts_0065;

procedure audit_payments_0475 is
  l_msg varchar2(200);
begin
  for r in (select id, region from bm_shipments_0475) loop
    l_msg := 'would update bm_rates_0475b for ' || r.id;
    dbms_output.put_line(l_msg);
    dbms_output.put_line(q'[delete from bm_rates_0475b; insert into x;]');
  end loop;
end audit_payments_0475;

procedure close_events_0493 is
  l_total number := 0;
begin
  for r in (select id, priority from bm_tickets_0493) loop
    l_total := l_total + r.priority;
  end loop;
  update bm_batches_0493b set amount_2 = l_total;
end close_events_0493;
end;
/
