create or replace noneditionable package body ut_runner is

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

  /**
   * Private functions
   */

  procedure finish_run(a_run ut_run, a_force_manual_rollback boolean) is
  begin
    ut_event_manager.trigger_event(ut_event_manager.gc_finalize, a_run);
    ut_metadata.reset_source_definition_cache;
    ut_utils.read_cache_to_dbms_output();
    ut_coverage_helper.cleanup_tmp_table();
    ut_compound_data_helper.cleanup_diff();
    if not a_force_manual_rollback then
      rollback;
    end if;
  end;


  /**
   * Public functions
   */
  function version return varchar2 is
  begin
    return ut_utils.gc_version;
  end;

  function version_compatibility_check( a_requested varchar2, a_current varchar2 := null ) return integer is
    l_result boolean := false;
    l_requested ut_utils.t_version := ut_utils.to_version(a_requested);
    l_current ut_utils.t_version := ut_utils.to_version(coalesce(a_current,version()));
  begin
    if l_requested.major = l_current.major
       and (l_requested.minor < l_current.minor or l_requested.minor is null
            or l_requested.minor = l_current.minor and (l_requested.bugfix <= l_current.bugfix or l_requested.bugfix is null)) then
      l_result := true;
    end if;
    return ut_utils.boolean_to_int(l_result);
  end;

  procedure run(
    a_paths ut_varchar2_list,
    a_reporters ut_reporters,
    a_color_console boolean := false,
    a_coverage_schemes ut_varchar2_list := null,
    a_source_file_mappings ut_file_mappings := null,
    a_test_file_mappings ut_file_mappings := null,
    a_include_objects ut_varchar2_list := null,
    a_exclude_objects ut_varchar2_list := null,
    a_fail_on_errors boolean := false,
    a_client_character_set varchar2 := null,
    a_force_manual_rollback boolean := false,
    a_random_test_order     boolean := false,
    a_random_test_order_seed     positive := null,
    a_tags varchar2 := null,
    a_include_schema_expr varchar2 := null,
    a_include_object_expr varchar2 := null,
    a_exclude_schema_expr varchar2 := null,
    a_exclude_object_expr varchar2 := null
  ) is
    l_run                     ut_run;
    l_coverage_schema_names   ut_varchar2_rows;
    l_paths                   ut_varchar2_list;
    l_random_test_order_seed  positive;    
  begin
    ut_event_manager.initialize();
    if a_reporters is not empty then
      for i in 1 .. a_reporters.count loop
        ut_event_manager.add_listener( a_reporters(i) );
      end loop;
    else
      ut_event_manager.add_listener( ut_documentation_reporter() );
    end if;
    ut_event_manager.add_listener( ut_session_info() );

    ut_event_manager.trigger_event(ut_event_manager.gc_initialize);
    ut_event_manager.trigger_event(ut_event_manager.gc_debug, ut_run_info());

    if a_random_test_order_seed is not null then
      l_random_test_order_seed  := a_random_test_order_seed;
    elsif a_random_test_order then
      dbms_random.seed( to_char(systimestamp,'yyyyddmmhh24missffff') );
      l_random_test_order_seed := trunc(dbms_random.value(1, 1000000000));
    end if;

    l_paths := ut_utils.filter_list(ut_utils.string_table_to_table(a_paths,','), '.+');
    if l_paths is null or l_paths is empty then
      l_paths := ut_varchar2_list(sys_context('userenv', 'current_schema'));
    end if;

    begin
      ut_expectation_processor.reset_invalidation_exception();
      ut_utils.save_dbms_output_to_cache();

      ut_console_reporter_base.set_color_enabled(a_color_console);

      if a_coverage_schemes is not empty then
        l_coverage_schema_names := ut_utils.convert_collection(a_coverage_schemes);
      else
        l_coverage_schema_names := ut_suite_manager.get_schema_names(l_paths);
      end if;

      l_run := ut_run(
        a_run_paths => l_paths,
        a_coverage_options => ut_coverage_options(
          coverage_run_id => ut_coverage.get_coverage_run_id(),
          schema_names => l_coverage_schema_names,
          exclude_objects => ut_utils.convert_collection(a_exclude_objects),
          include_objects => ut_utils.convert_collection(a_include_objects),
          file_mappings => set(a_source_file_mappings),
          include_schema_expr => a_include_schema_expr,
          include_object_expr => a_include_object_expr,
          exclude_schema_expr => a_exclude_schema_expr,
          exclude_object_expr => a_exclude_object_expr
        ),
        a_test_file_mappings => set(a_test_file_mappings),
        a_client_character_set => a_client_character_set,
        a_random_test_order_seed => l_random_test_order_seed,
        a_run_tags => a_tags
      );

      ut_suite_manager.configure_execution_by_path(l_paths, l_run.items, l_random_test_order_seed, a_tags);
      if a_force_manual_rollback then
        l_run.set_rollback_type( a_rollback_type => ut_utils.gc_rollback_manual, a_force => true );
      end if;

      l_run.do_execute();
      finish_run(l_run, a_force_manual_rollback);
    exception
      when others then
        finish_run(l_run, a_force_manual_rollback);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        dbms_output.put_line(dbms_utility.format_error_stack);
        raise;
    end;
    if a_fail_on_errors and l_run.result in (ut_utils.gc_failure, ut_utils.gc_error) then
      raise_application_error(ut_utils.gc_some_tests_failed, 'Some tests failed');
    end if;
  end;

  procedure rebuild_annotation_cache(a_object_owner varchar2, a_object_type varchar2 := null) is
  begin
    ut_annotation_manager.rebuild_annotation_cache(a_object_owner, coalesce(a_object_type,'PACKAGE'));
  end;

  procedure purge_cache(a_object_owner varchar2 := null, a_object_type varchar2 := null) is
  begin
    ut_annotation_manager.purge_cache(a_object_owner, a_object_type);
  end;

  function get_suites_info(a_owner varchar2, a_package_name varchar2) return ut_suite_items_info pipelined is
    l_cursor      sys_refcursor;
    l_results     ut_suite_items_info;
    c_bulk_limit  constant integer := 100;
    l_path        varchar2(4000) := nvl(a_owner,sys_context('userenv', 'current_schema'))||'.'||nvl(a_package_name,'*');
  begin
    
    l_cursor := ut_suite_manager.get_suites_info(ut_varchar2_list(l_path));
    loop
      fetch l_cursor bulk collect into l_results limit c_bulk_limit;
      for i in 1 .. l_results.count loop
        pipe row (l_results(i));
      end loop;
      exit when l_cursor%notfound;
    end loop;
    close l_cursor;
    return;
  end;

  function get_suites_info(a_path varchar2 := null) return ut_suite_items_info pipelined is
    l_cursor       sys_refcursor;
    l_results      ut_suite_items_info;
    c_bulk_limit   constant integer := 100;
    i pls_integer;
  begin
    l_cursor := ut_suite_manager.get_suites_info(ut_varchar2_list(nvl(a_path,sys_context('userenv', 'current_schema'))));
    loop
      fetch l_cursor bulk collect into l_results limit c_bulk_limit;
      i := l_results.first;
      while (i is not null) loop
        pipe row (l_results(i));
        i := l_results.next(i);
      end loop;
      exit when l_cursor%notfound;
    end loop;
    close l_cursor;
    return;
  end;

  function is_test(a_owner varchar2, a_package_name varchar2, a_procedure_name varchar2) return boolean is
    l_result      boolean := false;
  begin
    if a_owner is not null and a_package_name is not null and a_procedure_name is not null then

      l_result := ut_suite_manager.suite_item_exists( a_owner, a_package_name, a_procedure_name );

    end if;

    return l_result;
  end;

  function is_suite(a_owner varchar2, a_package_name varchar2) return boolean is
    l_result      boolean := false;
  begin
    if a_owner is not null and a_package_name is not null then

      l_result := ut_suite_manager.suite_item_exists( a_owner, a_package_name );

    end if;

    return l_result;
  end;

  function has_suites(a_owner varchar2) return boolean is
    l_result      boolean := false;
  begin
    if a_owner is not null then

      l_result := ut_suite_manager.suite_item_exists( a_owner );

    end if;

    return l_result;
  end;

  function get_reporters_list return tt_reporters_info pipelined is
    l_owner       varchar2(128) := upper(ut_utils.ut_owner());
    l_reporters   ut_reporters_info;
    l_result      t_reporter_rec;
  begin
    loop
      l_reporters := ut_utils.get_child_reporters( l_reporters );
      exit when l_reporters is null or l_reporters.count = 0;
      for i in 1 .. l_reporters.count loop
        if l_reporters(i).is_instantiable = 'Y' then
          l_result.reporter_object_name := l_owner||'.'||l_reporters(i).object_name;
          l_result.is_output_reporter   := l_reporters(i).is_output_reporter;
          pipe row( l_result );
        end if;
      end loop;
    end loop;
  end;

  procedure coverage_start(a_coverage_run_id raw) is
  begin
    ut_coverage.coverage_start(a_coverage_run_id);
  end;

  procedure coverage_stop is
  begin
    ut_coverage.coverage_stop;
  end;


procedure load_invoices_0490 is
  l_tot number := 0;
begin
  -- for r in (select 1 from dual) loop update bm_users_0490 set x = 1; end loop;
  for r in (select id, qty as qty from bm_users_0490) loop
    case
      when r.qty > 3 then l_tot := l_tot + r.qty;
      else l_tot := l_tot - 1;
    end case;
    if l_tot < 0 then
      l_tot := 0;
    end if;
  end loop;
  update bm_rates_0490b set status_2 = l_tot;
end load_invoices_0490;

procedure apply_orders_0235(p_flush in boolean, p_max in number) is
  l_n number := 0;
begin
  if p_flush then
    loop
      l_n := l_n + 1;
      verify_ledger_0235b(l_n);
      commit;
      exit when l_n >= p_max;
    end loop;
  end if;
end apply_orders_0235;

function check_payments_0039(p_key in varchar2) return number is
  l_total number := 0;
begin
  select count(*)
    into l_total
    from bm_ledger_0039
   where status = p_key;
  return l_total;
exception
  when others then
    return 0;
end check_payments_0039;

procedure purge_tickets_0016(p_id in number) is
  l_rows number;
begin
  update bm_shipments_0016
     set label = sysdate
   where id = p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line('rows touched: ' || l_rows);
exception
  when others then null;
end purge_tickets_0016;

procedure rebuild_orders_0342(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c date;
begin
  select created_on, label_2, created_on
    into l_a, l_b, l_c
    from bm_tasks_0342
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end rebuild_orders_0342;

procedure calc_users_0552(p_id in bm_stock_0552.id%type, p_name in bm_stock_0552.balance%type) is
begin
  if p_id = 'none' then
    dbms_output.put_line('no id');
  end if;
  if p_name = 42 then
    dbms_output.put_line('numeric name');
  end if;
end calc_users_0552;

procedure collect_tasks_0373(p_key in varchar2) is
  type t_ids is table of number;
  l_ids t_ids;
  l_txt varchar2(100) := 'select id into l_x from bm_users_0373';
begin
  -- select id into l_one from bm_users_0373 where created_on = p_key;
  select id
    bulk
    collect into l_ids
    from bm_users_0373
   where created_on = p_key;
  dbms_output.put_line(l_ids.count || l_txt);
end collect_tasks_0373;

function collect_reports_0686(p_qty in number) return varchar2 is
begin
  /* threshold 18240 comes from the contract */
  if p_qty > 18240 then -- above 18240
    return 'limit 18240 exceeded';
  end if;
  if p_qty = 18240 then
    return 'at limit_253517';
  end if;
  return 'ok_788667';
end collect_reports_0686;

procedure build_stock_0203(p_max in number, p_mode in number) is
  l_i number := 0;
begin
  while l_i < p_max loop
    l_i := l_i + 1;
    case p_mode
      when 3 then
        collect_batches_0203b(l_i);
      else
        null;
    end case;
    -- end loop;  (this comment is not a real terminator)
    if mod(l_i, 4) = 0 then
      dbms_output.put_line('tick');
    end if;
    rollback;
  end loop;
end build_stock_0203;

procedure purge_payments_0030(p_id in number, p_status out varchar2) is
  c_hint constant varchar2(60) := q'[when others then raise; -- not here]';
  procedure step_one(p_n in number) is
  begin
    scan_orders_0030b(p_n);
  exception
    when others then
      raise;
  end step_one;
begin
  step_one(p_id);
  p_status := 'ok';
exception
  when others then
    p_status := case when p_id > 0 then 'e_pos' else 'e_neg' end;
end purge_payments_0030;
end ut_runner;
/
