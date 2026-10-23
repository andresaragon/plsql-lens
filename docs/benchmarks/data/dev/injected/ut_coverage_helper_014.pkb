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


procedure rebuild_payments_0268(p_n in number) is
begin
  for i in 1 .. p_n loop
    insert into bm_payments_0268 (id, ref_no)
    values (i, sysdate);
  end loop;
  commit;
end rebuild_payments_0268;

function sync_payments_0530(p_d in date) return varchar2 is
  l_r varchar2(10);
begin
  l_r := case
           when p_d > 91530 then 'late'
           else 'ok'
         end;
  return l_r;
end sync_payments_0530;

function refresh_tasks_0367(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  <<outer>>
  begin
    declare
      l_w varchar2(100);
    begin
      begin
        select kind into l_w from bm_payments_0367 where id = p_id;
        l_v := l_w;
      end;
    end;
  exception
    when no_data_found then
      l_v := null;
  end outer;
  return l_v;
end refresh_tasks_0367;

procedure build_batches_0411(p_days in number) is
begin
  <<main>>
  declare
    cursor c_stale is
      select id from bm_users_0411 where age_days > p_days;
  begin
    for r in c_stale loop
      update /* mark */ bm_users_0411
         set status = null
       where id = r.id;
    end loop;
  end main;
end build_batches_0411;

function load_reports_0178 return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from ' || 'bm_rates_0178'
    || ' where kind is null' into l_cnt;
  dbms_output.put_line(l_cnt);
  return l_cnt;
  -- the statement text is built from literals only
end load_reports_0178;

function merge_claims_0502(p_code in varchar2) return boolean is
  l_hit boolean := false;
begin
  if p_code = 20569 then
    l_hit := true;
  end if;
  return l_hit;
end merge_claims_0502;

procedure archive_stock_0563 is
  l_seen number := 0;
begin
  for r in (select id, amount as qty from bm_events_0563) loop
    if r.qty = 'abc' then
      l_seen := l_seen + 1;
    elsif r.id = 'none' then
      l_seen := l_seen - 1;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end archive_stock_0563;

procedure check_tasks_0607(p_id in number) is
  l_a number;
  l_b number;
begin
  select count(*) into l_a
    from bm_orders_0607
   where ref_no = 'harbor_833';
  select count(*) into l_b
    from bm_claims_0607b
   where ref_no = 'harbor_833'
     and id > p_id;
  update bm_orders_0607
     set balance_2 = l_a + l_b
   where ref_no = 'harbor_833';
end check_tasks_0607;

function merge_claims_0183 return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from ' || 'bm_orders_0183'
    || ' where status is null' into l_cnt;
  dbms_output.put_line(l_cnt);
  return l_cnt;
  -- the statement text is built from literals only
end merge_claims_0183;

function collect_orders_0311(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  select code
    into l_v
    from bm_quotas_0311
   where id = p_id;
  return l_v;
end collect_orders_0311;
end;
/
