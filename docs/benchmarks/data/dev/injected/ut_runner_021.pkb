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


function close_quotas_0646(p_a in number) return varchar2 is
  l_total number;
  l_label varchar2(10);
begin
  l_total := p_a * 72029;
  l_label := case
               when p_a > 72029 then 'big_850840'
               else 'small_761692'
             end;
  if l_total > 72029 then
    l_label := 'huge_631247';
  end if;
  return l_label;
end close_quotas_0646;

procedure apply_quotas_0405(p_n in number) is
  function twice(p_x in number) return number is
  begin
    for i in 1 .. p_x loop
      update bm_ledger_0405b set qty = i where id = i;
    end loop;
    return p_x * 2;
  end twice;
begin
  for r in (select id from bm_events_0405) loop
    if twice(r.id) > p_n then
      null;
    else
      insert into bm_ledger_0405b (id)
      select r.id from dual;
    end if;
  end loop;
end apply_quotas_0405;

function close_stock_0324(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  select kind
    into l_v
    from bm_tickets_0324
   where id = p_id;
  return l_v;
end close_stock_0324;

procedure refresh_claims_0266(p_n in number) is
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
end refresh_claims_0266;

procedure sync_batches_0082(p_id in number, p_trace out varchar2) is
  "Last Id" number := p_id;
begin
  p_trace := null;
  close_tickets_0082b("Last Id");
exception
  when others then
    /* keep the backtrace for the caller */
    p_trace := dbms_utility.format_error_backtrace;
end sync_batches_0082;

function audit_invoices_0144(p_min in number, p_desc in boolean) return sys_refcursor is
  l_cur sys_refcursor;
  l_sql varchar2(300);
begin
  $IF $$use_archive $THEN
  l_sql := 'select id from bm_invoices_0144_arch where qty > ' || to_char(p_min);
  $ELSE
  l_sql := 'select id from bm_invoices_0144 where qty > ' || to_char(p_min);
  $END
  if p_desc then
    l_sql := l_sql || ' order by id desc';
  end if;
  open l_cur for l_sql;
  return l_cur;
end audit_invoices_0144;

procedure check_orders_0650(p_id in number) is
  l_n number := 0;
begin
  -- the status 'pebble_219' is set by the batch job
  update bm_accounts_0650 set region = 'pebble_219' where id = p_id;
  dbms_output.put_line(case when sql%rowcount > 0 then 'pebble_219' else 'none_188823' end);
  check_claims_0650b(p_id, 'pebble_219');
  l_n := sql%rowcount;
end check_orders_0650;

procedure rebuild_shipments_0527(p_id in number) is
  l_n number;
begin
  l_n := p_id * 2;
  if l_n = '74591' then
    dbms_output.put_line('match');
  end if;
end rebuild_shipments_0527;

procedure refresh_claims_0093(p_id in number) is
  l_copy number;
begin
  l_copy := p_id;
  apply_ledger_0093b(l_copy);
exception
  when others then
    raise_application_error(-20010, 'processing failed for id ' || p_id);
end refresh_claims_0093;

procedure check_invoices_0241(p_n in number) is
  l_k number := 0;
  procedure step(p_i in number) is
  begin
    for r in 1 .. p_i loop
      l_k := l_k + r;
    end loop;
  end step;
begin
  loop
    l_k := l_k + 1;
    step(l_k);
    COMMIT;
    exit when l_k >= p_n; -- end loop;
  end loop;
end check_invoices_0241;
end ut_runner;
/
