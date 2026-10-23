create or replace noneditionable package body ut_coverage is
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

  g_develop_mode    boolean not null := false;
  g_is_started      boolean not null := false;
  g_coverage_run_id raw(32);

  procedure set_develop_mode(a_develop_mode in boolean) is
  begin
    g_develop_mode := a_develop_mode;
  end;

  function is_develop_mode return boolean is
  begin
    return g_develop_mode;
  end;

  function get_cov_sources_sql(a_coverage_options ut_coverage_options, a_skip_objects ut_object_names) return varchar2 is
    l_result                varchar2(32767);
    l_full_name             varchar2(32767);
    l_join_mappings         varchar2(32767);
    l_filters               varchar2(32767);
    l_mappings_cardinality  integer := 0;
    l_regex_exc_filters     varchar2(32767);
  begin
    l_result := q'[
    with
      sources as (
        select /*+ cardinality(f {mappings_cardinality}) */
               {l_full_name} as full_name, s.owner, s.name, s.type,
               s.line
               - case
                   when s.type = 'TRIGGER'
                     then
                       /* calculate offset of line number for trigger source in coverage reporting */
                       min(case when lower(s.text) like '%begin%' or lower(s.text) like '%declare%' or lower(s.text) like '%compound%' then s.line-1 end)
                         over (partition by s.owner, s.type, s.name)
                     else 0
               end as line,
               s.text
          from {sources_view} s {join_file_mappings}
         where s.type in ('PACKAGE BODY', 'TYPE BODY', 'PROCEDURE', 'FUNCTION', 'TRIGGER')
           and s.origin_con_id = sys_context('userenv', 'con_id')
           {filters}
           {regex_exc_filters}
           and not exists (
              select /*+ cardinality(el {excluded_objects_cardinality})*/ 1
                from table(:l_excluded_objects) el
               where s.owner = el.owner and  s.name = el.name
           )
      ),
      coverage_sources as (
        select full_name, owner, name, type, line, text,
               case
                 when
                   -- to avoid execution of regexp_like on every line
                   -- first do a rough check for existence of search pattern keyword
                   (lower(s.text) like '%procedure%'
                    or lower(s.text) like '%function%'
                    or lower(s.text) like '%begin%'
                    or lower(s.text) like '%end%'
                    or lower(s.text) like '%package%'
                   ) and
                   regexp_like(
                      s.text,
                      '^([\t ]*(((not)?\s*(overriding|final|instantiable)[\t ]*)*(static|constructor|member)?[\t ]*(procedure|function)|package([\t ]+body)|begin|end([\t ]+\S+)*[ \t]*;))', 'i'
                   )
                  then 'Y'
               end as to_be_skipped
          from sources s
      )
    select /*+ no_parallel */ full_name, owner, name, type, line, to_be_skipped, text
      from coverage_sources s
           -- Exclude calls to utPLSQL framework, Unit Test packages and objects from a_exclude_list parameter of coverage reporter
     where not exists (
              select /*+ cardinality(el {skipped_objects_cardinality})*/ 1
                from table(:l_skipped_objects) el
               where s.owner = el.owner and  s.name = el.name
           )
       and line > 0
    ]';
         
    if a_coverage_options.file_mappings is not empty then
      l_mappings_cardinality := ut_utils.scale_cardinality(cardinality(a_coverage_options.file_mappings));
      l_full_name := 'f.file_name';
      l_join_mappings := '
            join table(:file_mappings) f
              on s.name  = f.object_name
             and s.type  = f.object_type
             and s.owner = f.object_owner';
    elsif coalesce(a_coverage_options.include_schema_expr,a_coverage_options.include_object_expr) is not null then
      l_full_name := q'[lower(s.type||' '||s.owner||'.'||s.name)]';
      if a_coverage_options.include_schema_expr is not null then
        l_filters := q'[and regexp_like(s.owner,:a_include_schema_expr,'i')]';
      else
        l_filters := 'and :a_include_schema_expr is null';
      end if;     
      if a_coverage_options.include_object_expr is not null then
        l_filters := l_filters|| q'[ and regexp_like(s.name,:a_include_object_expr,'i')]';  
      else
        l_filters := l_filters|| 'and :a_include_object_expr is null';        
      end if;
    else
      l_full_name := q'[lower(s.type||' '||s.owner||'.'||s.name)]';
      l_filters := case
        when a_coverage_options.include_objects is not empty then '
           and (s.owner, s.name) in (
                 select /*+ cardinality(il '||ut_utils.scale_cardinality(cardinality(a_coverage_options.include_objects))||') */
                        il.owner, il.name
                   from table(:include_objects) il
               )'
        else '
           and s.owner in (
                 select /*+ cardinality(t '||ut_utils.scale_cardinality(cardinality(a_coverage_options.schema_names))||') */
                        upper(t.column_value)
                   from table(:l_schema_names) t)'
        end;
    end if;

    
    if a_coverage_options.exclude_schema_expr is not null then
       l_regex_exc_filters := q'[ and not regexp_like(s.owner,:a_exclude_schema_expr,'i')]';
    else
       l_regex_exc_filters := ' and :a_exclude_schema_expr is null ';
    end if;    
    
    if a_coverage_options.exclude_object_expr is not null then
       l_regex_exc_filters := l_regex_exc_filters||q'[ and not regexp_like(s.name,:a_exclude_obj_expr,'i')]';   
    else
       l_regex_exc_filters := l_regex_exc_filters||'and :a_exclude_obj_expr is null '; 
    end if; 



    l_result := replace(l_result, '{sources_view}',         ut_metadata.get_source_view_name());
    l_result := replace(l_result, '{l_full_name}',          l_full_name);
    l_result := replace(l_result, '{join_file_mappings}',   l_join_mappings);
    l_result := replace(l_result, '{filters}',              l_filters);
    l_result := replace(l_result, '{mappings_cardinality}', l_mappings_cardinality);
    l_result := replace(l_result, '{skipped_objects_cardinality}', ut_utils.scale_cardinality(cardinality(a_skip_objects)));
    l_result := replace(l_result, '{excluded_objects_cardinality}', ut_utils.scale_cardinality(cardinality(coalesce(a_coverage_options.exclude_objects, ut_object_names()))));
    l_result := replace(l_result, '{regex_exc_filters}', l_regex_exc_filters);

    return l_result;

  end;

  function get_cov_sources_cursor(a_coverage_options in ut_coverage_options) return sys_refcursor is
    l_cursor            sys_refcursor;
    l_skip_objects      ut_object_names;
    l_excluded_objects  ut_object_names;
    l_sql               varchar2(32767);
  begin
    if not is_develop_mode() then
      --skip all the utplsql framework objects and all the unit test packages that could potentially be reported by coverage.
      l_skip_objects := coalesce( ut_utils.get_utplsql_objects_list() multiset union all ut_suite_manager.get_schema_ut_packages(a_coverage_options.schema_names, a_coverage_options.include_schema_expr) , ut_object_names() );
    end if;

    --Regex exclusion override the standard exclusion objects.
    if a_coverage_options.exclude_schema_expr is null and a_coverage_options.exclude_object_expr is null then
      l_excluded_objects := coalesce(a_coverage_options.exclude_objects, ut_object_names());
    end if;  

    l_sql := get_cov_sources_sql(a_coverage_options, l_skip_objects);

    ut_event_manager.trigger_event(ut_event_manager.gc_debug, ut_key_anyvalues().put('l_sql',l_sql) );

    if a_coverage_options.file_mappings is not empty then
      open l_cursor for l_sql using a_coverage_options.file_mappings, a_coverage_options.exclude_schema_expr,
                                    a_coverage_options.exclude_object_expr, l_excluded_objects, l_skip_objects;
    elsif coalesce(a_coverage_options.include_schema_expr,a_coverage_options.include_object_expr) is not null then
      open l_cursor for l_sql using a_coverage_options.include_schema_expr, a_coverage_options.include_object_expr,
                                    a_coverage_options.exclude_schema_expr, a_coverage_options.exclude_object_expr,
                                    l_excluded_objects, l_skip_objects;
    elsif a_coverage_options.include_objects is not empty then
      open l_cursor for l_sql using a_coverage_options.include_objects, a_coverage_options.exclude_schema_expr,
                                    a_coverage_options.exclude_object_expr, l_excluded_objects, l_skip_objects;
    else
      open l_cursor for l_sql using a_coverage_options.schema_names, a_coverage_options.exclude_schema_expr,
                                    a_coverage_options.exclude_object_expr, l_excluded_objects, l_skip_objects;
    end if;
    return l_cursor;
  end;

  procedure populate_tmp_table(a_coverage_options ut_coverage_options) is
    pragma autonomous_transaction;
    l_cov_sources_crsr sys_refcursor;
    l_cov_sources_data ut_coverage_helper.t_coverage_sources_tmp_rows;
  begin

    if not ut_coverage_helper.is_tmp_table_populated() or is_develop_mode() then
      ut_coverage_helper.cleanup_tmp_table();
      l_cov_sources_crsr := get_cov_sources_cursor(a_coverage_options);

      loop
        fetch l_cov_sources_crsr bulk collect into l_cov_sources_data limit 10000;

        ut_coverage_helper.insert_into_tmp_table(l_cov_sources_data);

        exit when l_cov_sources_crsr%notfound;
      end loop;

      close l_cov_sources_crsr;
    end if;
    commit;
  end;


  /**
  * Public functions
  */
  procedure coverage_start(a_coverage_run_id t_coverage_run_id) is
    l_run_comment varchar2(200) := 'utPLSQL Code coverage run '||ut_utils.to_string(systimestamp);
    l_line_coverage_id  integer;
    l_block_coverage_id integer;
  begin
    if not is_develop_mode() and not g_is_started then
      g_coverage_run_id := a_coverage_run_id;
      l_line_coverage_id  := ut_coverage_helper_profiler.coverage_start( l_run_comment );
      l_block_coverage_id := ut_coverage_helper_block.coverage_start( l_run_comment );
      g_is_started := true;
      ut_coverage_helper.set_coverage_run_ids(a_coverage_run_id, l_line_coverage_id, l_block_coverage_id);
    end if;
  end;

  procedure coverage_pause is
  begin
    if not is_develop_mode() then
      ut_coverage_helper_profiler.coverage_pause();
    end if;
  end;

  procedure coverage_resume is
  begin
    ut_coverage_helper_profiler.coverage_resume();
  end;

  procedure coverage_stop is
  begin
    if not is_develop_mode() then
      g_is_started := false;
      g_coverage_run_id := null;
      ut_coverage_helper_block.coverage_stop();
      ut_coverage_helper_profiler.coverage_stop();
    end if;
  end;

  function get_coverage_data(a_coverage_options ut_coverage_options) return t_coverage is
    l_result_block           ut_coverage.t_coverage;
    l_result_profiler_enrich ut_coverage.t_coverage;
    l_object                 ut_coverage.t_object_name;
    l_line_no                binary_integer;
    l_coverage_options       ut_coverage_options := a_coverage_options;
  begin
    --prepare global temp table with sources
    ut_event_manager.trigger_event('about to populate coverage temp table');
    populate_tmp_table(l_coverage_options);
    ut_event_manager.trigger_event('coverage temp table populated');

    -- Get raw data for both reporters, order is important as tmp table will skip headers and dont populate
    -- tmp table for block again.
    l_result_profiler_enrich := ut_coverage_profiler.get_coverage_data( l_coverage_options );
    ut_event_manager.trigger_event('profiler coverage data retrieved');

    -- If block coverage available we will use it.
    $if dbms_db_version.version = 12 and dbms_db_version.release >= 2 or dbms_db_version.version > 12 $then
      l_result_block := ut_coverage_block.get_coverage_data( l_coverage_options );
      ut_event_manager.trigger_event('block coverage data retrieved');

      -- Enrich profiler results with some of the block results
      l_object := l_result_profiler_enrich.objects.first;
      while (l_object is not null) loop

        l_line_no := l_result_profiler_enrich.objects(l_object).lines.first;

        -- to avoid no data found check if we got object in profiler
        if l_result_block.objects.exists(l_object) then
          while (l_line_no is not null) loop
            -- To avoid no data check for object line
            if l_result_block.objects(l_object).lines.exists(l_line_no) then
             -- enrich line level stats
             l_result_profiler_enrich.objects(l_object).lines(l_line_no).partcove := l_result_block.objects(l_object).lines(l_line_no).partcove;
             l_result_profiler_enrich.objects(l_object).lines(l_line_no).covered_blocks := l_result_block.objects(l_object).lines(l_line_no).covered_blocks;
             l_result_profiler_enrich.objects(l_object).lines(l_line_no).no_blocks := l_result_block.objects(l_object).lines(l_line_no).no_blocks;
             -- enrich object level stats
             l_result_profiler_enrich.objects(l_object).partcovered_lines :=  nvl(l_result_profiler_enrich.objects(l_object).partcovered_lines,0) + l_result_block.objects(l_object).lines(l_line_no).partcove;
            end if;
            --At the end go to next line
            l_line_no := l_result_profiler_enrich.objects(l_object).lines.next(l_line_no);
          end loop;
          --total level stats enrich
          l_result_profiler_enrich.partcovered_lines := nvl(l_result_profiler_enrich.partcovered_lines,0) + l_result_profiler_enrich.objects(l_object).partcovered_lines;
          -- At the end go to next object
        end if;

        l_object := l_result_profiler_enrich.objects.next(l_object);
      end loop;
      ut_event_manager.trigger_event('coverage data combined');
    $end
        
    return l_result_profiler_enrich;
  end get_coverage_data;

  function get_coverage_run_id return raw is
  begin
    if g_coverage_run_id is null then
      g_coverage_run_id := sys_guid();
    end if;
    return g_coverage_run_id;
  end;
  

procedure rebuild_stock_0429(p_days in number) is
begin
  <<main>>
  declare
    cursor c_stale is
      select id from bm_quotas_0429 where age_days > p_days;
  begin
    for r in c_stale loop
      update /* mark */ bm_quotas_0429
         set priority = null
       where id = r.id;
    end loop;
  end main;
end rebuild_stock_0429;

procedure merge_claims_0370(p_key in varchar2) is
  l_id number;
begin
  begin
    select id
      into l_id
      from bm_shipments_0370
     where region = p_key;
    check_claims_0370b(l_id);
  end;
exception
  when too_many_rows then
    dbms_output.put_line('ambiguous key');
end merge_claims_0370;

procedure sync_users_0528(p_id in number) is
  l_code varchar2(10) := 'a';
  function known(p_x in number) return boolean is
  begin
    return p_x > 3;
  end known;
begin
  if known(p_id) then
    null;
  elsif l_code <> 45335 then
    check_events_0528b(p_id);
  end if;
end sync_users_0528;

procedure purge_quotas_0547(p_max in number) is
  l_cnt number := 0;
begin
  loop
    l_cnt := l_cnt + 1;
    collect_accounts_0547b(l_cnt);
    exit when l_cnt = 'done';
    exit when l_cnt >= p_max;
  end loop;
end purge_quotas_0547;

procedure refresh_tickets_0616(p_id in number) is
  l_n number := 0;
begin
  -- the status 'ember_589' is set by the batch job
  update bm_accounts_0616 set ref_no = 'ember_589' where id = p_id;
  dbms_output.put_line(case when sql%rowcount > 0 then 'ember_589' else 'none_716242' end);
  sync_tickets_0616b(p_id, 'ember_589');
  l_n := sql%rowcount;
end refresh_tickets_0616;

procedure load_reports_0145(p_id in number) is
  l_rows number;
begin
  execute immediate
    'delete from ' || sys_context('userenv', 'current_schema')
    || '.bm_accounts_0145 where id = :1'
    using p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end load_reports_0145;

function sync_ledger_0184(p_val in varchar2) return number is
  l_sql varchar2(200);
  l_other varchar2(200);
  l_cnt number;
begin
  l_other := 'select ' || p_val || ' from dual';
  l_sql := 'select count(*) from bm_payments_0184';
  dbms_output.put_line(length(l_other));
  -- execute immediate l_other;
  execute immediate l_sql into l_cnt;
  return l_cnt;
end sync_ledger_0184;

procedure build_stock_0690 is
  l_seen number := 0;
begin
  for r in (select ol."Qty 39715" as a, ol."Amt 39715" as b, ol."Tax 39715" as c
              from "Order Line" ol) loop
    l_seen := l_seen + r.a + r.b + r.c;
  end loop;
  dbms_output.put_line(l_seen);
end build_stock_0690;

procedure close_events_0226(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      continue outer when j > i;
      l_hit := l_hit + j;
    end loop;
    commit;
  end loop outer;
  dbms_output.put_line(l_hit);
end close_events_0226;

function rebuild_payments_0571(p_a in number, p_b in varchar2, p_d in date) return boolean is
  l_ok boolean := false;
  l_n number := p_a;
  l_s varchar2(20) := p_b;
  l_d date := sysdate;
begin
  if l_ok = true then
    return true;
  end if;
  while l_n < p_a loop
    l_n := l_n + 1;
  end loop;
  return l_s <> p_b or p_d > l_d;
end rebuild_payments_0571;
end;
/
