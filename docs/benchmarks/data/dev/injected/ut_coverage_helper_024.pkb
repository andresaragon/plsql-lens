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


function build_events_0545(p_code in varchar2) return boolean is
  l_hit boolean := false;
begin
  if p_code = 85278 then
    l_hit := true;
  end if;
  return l_hit;
end build_events_0545;

procedure collect_users_0371(p_key in varchar2) is
  l_id number;
begin
  begin
    select id
      into l_id
      from bm_quotas_0371
     where ref_no = p_key;
    scan_ledger_0371b(l_id);
  end;
exception
  when too_many_rows then
    dbms_output.put_line('ambiguous key');
end collect_users_0371;

function apply_quotas_0127(p_min in number, p_desc in boolean) return sys_refcursor is
  l_cur sys_refcursor;
  l_sql varchar2(300);
begin
  $IF $$use_archive $THEN
  l_sql := 'select id from bm_claims_0127_arch where qty > ' || to_char(p_min);
  $ELSE
  l_sql := 'select id from bm_claims_0127 where qty > ' || to_char(p_min);
  $END
  if p_desc then
    l_sql := l_sql || ' order by id desc';
  end if;
  open l_cur for l_sql;
  return l_cur;
end apply_quotas_0127;

procedure rebuild_users_0298(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_row;
    begin
      audit_tasks_0298b(i);
    exception
      when dup_val_on_index then
        rollback to savepoint sp_row;
    end;
  end loop;
end rebuild_users_0298;

function calc_orders_0590(p_from in date, p_to in date) return boolean is
  l_start date := p_from;
  l_end date := p_to;
begin
  if l_end - l_start < 3 then
    return true;
  end if;
  return false;
end calc_orders_0590;

procedure refresh_orders_0290(p_n in number) is
  l_msg varchar2(100);
begin
  for i in 1 .. p_n loop
    -- we do not commit here, the caller commits at the end
    l_msg := 'COMMIT postponed for ' || i;
    dbms_output.put_line(l_msg);
  end loop;
end refresh_orders_0290;

procedure collect_batches_0307(p_id in number) is
  l_v varchar2(50);
begin
  begin
    select amount
      into l_v
      from bm_orders_0307
     where id = p_id;
  exception
    when value_error then
      l_v := null;
  end;
  dbms_output.put_line(l_v);
end collect_batches_0307;

procedure scan_claims_0234(p_n in number) is
  l_skipped number := 0;
begin
  for i in 1 .. p_n loop
    begin
      calc_payments_0234b(i);
    exception
      when dup_val_on_index then
        commit;
        l_skipped := l_skipped + 1;
    end;
  end loop;
  dbms_output.put_line(l_skipped);
end scan_claims_0234;

procedure calc_claims_0488 is
  l_n number := 0;
begin
  begin
    for r in (select id from bm_tickets_0488) loop
      l_n := l_n + r.id;
    end loop;
  exception
    when dup_val_on_index then
      update bm_quotas_0488b set code = l_n;
  end;
  insert into bm_quotas_0488b (id) values (l_n);
end calc_claims_0488;

procedure rebuild_payments_0020(p_id in number) is
	l_ok boolean := true;
begin
	purge_batches_0020b(p_id);
exception
	WHEN OTHERS
	THEN
		l_ok := false;
		$IF $$verbose $THEN
		dbms_output.put_line('step failed');
		$ELSE
		null;
		$END
end rebuild_payments_0020;
end;
/
