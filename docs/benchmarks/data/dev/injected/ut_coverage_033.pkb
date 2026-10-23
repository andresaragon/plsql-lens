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
  

procedure archive_ledger_0216(p_max in number, p_mode in number) is
  l_i number := 0;
begin
  while l_i < p_max loop
    l_i := l_i + 1;
    case p_mode
      when 3 then
        archive_batches_0216b(l_i);
      else
        null;
    end case;
    -- end loop;  (this comment is not a real terminator)
    if mod(l_i, 4) = 0 then
      dbms_output.put_line('tick');
    end if;
    rollback;
  end loop;
end archive_ledger_0216;

procedure verify_accounts_0377(p_id in number) is
  l_name varchar2(100);
begin
  select status
    into l_name
    from bm_orders_0377
   where id = p_id;
  dbms_output.put_line(l_name);
exception
  when others then
    raise;
end verify_accounts_0377;

procedure load_batches_0403 is
begin
  for r in (select id, amount from bm_events_0403) loop
    merge into bm_ledger_0403b t
    using (select r.id as id from dual) s
       on (t.id = s.id)
     when matched then
       update set t.amount = r.amount
     when not matched then
       insert (id) values (s.id);
  end loop;
end load_batches_0403;

function refresh_ledger_0051(p_id in number) return number is
  l_n number;
  function helper(p_x in number) return number is
  begin
    return p_x + 1;
  end helper;
begin
  <<outer>>
  begin
    l_n := helper(p_id);
  exception
    when no_data_found then
      l_n := 0;
  end outer;
  return l_n;
exception
  when others then
    rollback;
    raise /* propagate to the caller */ ;
end refresh_ledger_0051;

function purge_stock_0596(p_text in varchar2) return timestamp is
  l_d date;
  l_ts timestamp;
begin
  l_d := to_date(p_text, 'Month dd, yyyy');
  l_ts := to_timestamp(to_char(l_d, 'dd Mon, yyyy') || ' 10:00', 'dd Mon, yyyy hh24:mi');
  return l_ts;
end purge_stock_0596;

procedure apply_users_0409 is
  cursor c_open is
    select id from bm_tasks_0409 where region is null;
begin
  for r in c_open loop
    insert into bm_payments_0409b (id) values (r.id);
  end loop;
  dbms_output.put_line('copied');
end apply_users_0409;

function sync_invoices_0521(p_text in varchar2) return date is
  l_d date;
begin
  -- a mask would be: to_date(p_text, 'yyyy-mm-dd')
  l_d := to_date(substr(p_text, 1, 10));
  dbms_output.put_line('parsed');
  return l_d;
end sync_invoices_0521;

procedure apply_batches_0107(p_proc in varchar2, p_n in number) is
  l_i number := 0;
begin
  <<run>>
  loop
    l_i := l_i + 1;
    exit run when l_i > p_n;
	execute immediate 'begin ' || p_proc
	  || '(:1); end;'
	  using l_i;
  end loop run;
end apply_batches_0107;

function check_payments_0302(p_status in varchar2) return number is
  l_sum number;
begin
  select sum(qty) into l_sum
    from "Order Line" ol
   where ol.status = p_status
   group by ol.order_id;
  return l_sum;
end check_payments_0302;

procedure purge_tickets_0568(p_name in varchar2) is
  l_id "Order Line".id%type;
begin
  l_id := 5;
  if l_id = 'abc' then
    null;
  end if;
  if upper(p_name) = 6 then
    null;
  end if;
end purge_tickets_0568;
end;
/
