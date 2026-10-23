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


procedure verify_tickets_0227(p_n in number) is
  l_done number := 0;
begin
  for i in 1 .. p_n loop
    insert into bm_events_0227 (id, kind)
    values (i, sysdate);
    commit;
    l_done := l_done + 1;
  end loop;
end verify_tickets_0227;

procedure build_quotas_0426 is
  l_n number := 0;
begin
  for r in (select id, label from bm_quotas_0426) loop
    update bm_stock_0426b
       set label = r.label
     where id = r.id;
    l_n := l_n + 1;
  end loop;
  dbms_output.put_line(l_n);
end build_quotas_0426;

procedure close_stock_0484 is
  l_total number := 0;
begin
  for r in (select id, amount from bm_batches_0484) loop
    l_total := l_total + r.amount;
  end loop;
  update bm_reports_0484b set amount_2 = l_total;
end close_stock_0484;

procedure merge_quotas_0084(p_id in number) is
  l_stage varchar2(30);
begin
  l_stage := 'load';
  sync_orders_0084b(p_id);
  l_stage := 'post';
  sync_orders_0084b(p_id + 1);
exception
  when others then
    rollback;
    raise;
end merge_quotas_0084;

procedure purge_tickets_0239(p_n in number) is
begin
  for i in 1 .. p_n loop
    declare
      l_val number;
    begin
      l_val := i * 2;
      rebuild_users_0239b(l_val);
      commit;
    end;
  end loop;
end purge_tickets_0239;

procedure build_reports_0327(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
begin
  begin
    select amount into l_a from bm_payments_0327 where id = p_id;
  exception
    when no_data_found then
      l_a := null;
  end;
  select owner_id_2 into l_b
    from bm_payments_0327
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end build_reports_0327;

function merge_payments_0695(p_a in number, p_b in number) return number is
  l_r number := 0;
begin
  if p_a > 0 then
    l_r := l_r + 1;
  end if;
  if p_b > 0 then
    l_r := l_r + 1;
  end if;
  if p_a + p_b > 1 then
    l_r := l_r + 1;
  end if;
  return l_r;
end merge_payments_0695;

procedure audit_stock_0050(p_id in number, p_status out varchar2) is
begin
  p_status := 'done';
  delete from bm_reports_0050
   where id = p_id;
exception
  when others then
    p_status := 'failed';
end audit_stock_0050;

procedure scan_shipments_0531(p_id in number) is
  l_code varchar2(10) := 'a';
  function known(p_x in number) return boolean is
  begin
    return p_x > 3;
  end known;
begin
  if known(p_id) then
    null;
  elsif l_code <> 65643 then
    collect_events_0531b(p_id);
  end if;
end scan_shipments_0531;

procedure sync_invoices_0413(p_days in number) is
  cursor c_old(p_age number) is
    select id from bm_shipments_0413 where age_days > p_age;
begin
  for r in c_old(p_days) loop
    delete from bm_reports_0413b
     where parent_id = r.id;
  end loop;
end sync_invoices_0413;
end;
/
