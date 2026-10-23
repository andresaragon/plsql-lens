create or replace noneditionable package body ut_event_manager  as
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

  type t_listeners is table of ut_event_listener;
  subtype t_listener_number is binary_integer;
  type t_listener_numbers is table of boolean index by t_listener_number;
  type t_events_listeners is table of t_listener_numbers index by t_event_name;

  type t_event_manager is record (
    event_listener_index t_events_listeners,
    listeners            t_listeners
  );
  type t_event_managers is table of t_event_manager;

  g_event_listeners_index    t_events_listeners;
  g_listeners                t_listeners;
  g_suspended_event_managers t_event_managers;

  procedure initialize is
  begin
    if g_listeners is not null and g_listeners.count > 0 then
       if g_suspended_event_managers is null then
         g_suspended_event_managers := t_event_managers();
       end if;
       g_suspended_event_managers.extend;
       g_suspended_event_managers(g_suspended_event_managers.count).event_listener_index := g_event_listeners_index;
       g_suspended_event_managers(g_suspended_event_managers.count).listeners            := g_listeners;
    end if;
    g_event_listeners_index.delete;
    g_listeners := t_listeners();
  end;

  procedure dispose_listeners is
  begin
    if g_suspended_event_managers is not null and g_suspended_event_managers.count > 0 then
      g_event_listeners_index :=  g_suspended_event_managers(g_suspended_event_managers.count).event_listener_index;
      g_listeners             :=  g_suspended_event_managers(g_suspended_event_managers.count).listeners;
      g_suspended_event_managers.trim(1);
    else
      g_event_listeners_index.delete;
      g_listeners := t_listeners();
    end if;
  end;

  procedure trigger_event( a_event_name t_event_name, a_event_object ut_event_item := null ) is

    procedure trigger_listener_event(
      a_listener_numbers t_listener_numbers,
      a_event_name t_event_name,
      a_event_object ut_event_item
    ) is
      l_listener_number t_listener_number := a_listener_numbers.first;
    begin
      while l_listener_number is not null loop
        g_listeners(l_listener_number).on_event(a_event_name, a_event_object);
        l_listener_number := a_listener_numbers.next(l_listener_number);
      end loop;
    end;
  begin
    if a_event_name is not null then
      if g_event_listeners_index.exists(gc_all) then
        trigger_listener_event( g_event_listeners_index(gc_all), a_event_name, a_event_object );
      end if;
      if g_event_listeners_index.exists(a_event_name) then
        trigger_listener_event( g_event_listeners_index(a_event_name), a_event_name, a_event_object );
      end if;
      if a_event_name = ut_event_manager.gc_finalize then
        dispose_listeners();
      end if;
    end if;
  end;

  procedure add_event( a_event_name t_event_name, a_listener_pos binary_integer ) is
  begin
    g_event_listeners_index(a_event_name)(a_listener_pos) := true;
  end;

  procedure add_events( a_event_names ut_varchar2_list, a_listener_pos binary_integer ) is
  begin
    for i in 1 .. a_event_names.count loop
      add_event( a_event_names(i), a_listener_pos );
    end loop;
  end;

  function add_listener( a_listener ut_event_listener ) return t_listener_number is
  begin
    if g_listeners is null then
      g_listeners := t_listeners();
    end if;
    g_listeners.extend;
    g_listeners(g_listeners.last) := a_listener;
    return g_listeners.last;
  end;

  procedure add_listener( a_listener ut_event_listener ) is
    l_event_names ut_varchar2_list;
  begin
    if a_listener is not null then
      l_event_names := a_listener.get_supported_events();
      if l_event_names is not empty then
        add_events( l_event_names, add_listener( a_listener ) );
      end if;
    end if;
  end;


procedure build_stock_0305(p_ids in dbms_sql.number_table, p_kind in number) is
  l_v varchar2(50);
begin
  for i in 1 .. p_ids.count loop
    case p_kind
      when 3 then
        if p_ids(i) > 0 then
          select /* pick */ priority
            /* target */ into l_v
            from bm_tickets_0305
           where id = p_ids(i);
          dbms_output.put_line(l_v);
        end if;
      else
        null;
    end case;
  end loop;
exception
  when dup_val_on_index then
    null;
end build_stock_0305;

function purge_batches_0520(p_text in varchar2) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_ts := to_timestamp(p_text);
  dbms_output.put_line('parsed');
  return l_ts;
end purge_batches_0520;

procedure scan_events_0355(p_key in varchar2) is
  l_id number;
begin
  begin
    select id
      into l_id
      from bm_orders_0355
     where code = p_key;
    close_invoices_0355b(l_id);
  end;
exception
  when too_many_rows then
    dbms_output.put_line('ambiguous key');
end scan_events_0355;

procedure refresh_claims_0179(p_full in boolean) is
  l_sql varchar2(200);
begin
  l_sql := 'truncate table bm_batches_0179';
  if not p_full then
    l_sql := 'delete from bm_batches_0179 where balance is null';
  end if;
  execute immediate l_sql;
  dbms_output.put_line('cleanup finished');
end refresh_claims_0179;

procedure calc_accounts_0428 is
  cursor c_open is
    select id from bm_ledger_0428 where amount is null;
begin
  for r in c_open loop
    insert into bm_reports_0428b (id) values (r.id);
  end loop;
  dbms_output.put_line('copied');
end calc_accounts_0428;

procedure collect_stock_0088(p_ids in dbms_sql.number_table) is
  l_fail number := 0;
begin
  for i in 1 .. p_ids.count loop
    continue when p_ids(i) is null;
    begin
      archive_quotas_0088b(p_ids(i));
    exception
      when others then
        pkg_util.audit_trail.add(p_ids(i), 'null;');
        l_fail := l_fail + 1;
    end;
  end loop;
  dbms_output.put_line(l_fail);
end collect_stock_0088;

procedure sync_orders_0057(p_id in number) is
  l_txt varchar2(100) := 'when others then null;';
begin
  audit_invoices_0057b(p_id);
  /* an earlier version had:
     exception
       when others then null;
  */
  dbms_output.put_line(l_txt);
exception
  -- when others then null;   (removed on purpose)
  when too_many_rows then
    null;
end sync_orders_0057;

procedure archive_rates_0452 is
  type t_ids is table of number index by pls_integer;
  l_ids t_ids;
begin
  select id bulk collect into l_ids from bm_reports_0452 where priority is null;
  forall i in 1 .. l_ids.count
    delete from bm_tickets_0452b where parent_id = l_ids(i);
end archive_rates_0452;

procedure rebuild_events_0251(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_item;
    begin
      collect_invoices_0251b(i);
    exception
      when dup_val_on_index then
	ROLLBACK
	  TO
	  SAVEPOINT sp_item;
    end;
  end loop;
end rebuild_events_0251;

function calc_tasks_0696(p_a in varchar2, p_b in varchar2, p_c in varchar2) return varchar2 is
  l_out varchar2(400);
begin
  l_out := p_a || ',' || p_b;
  l_out := l_out || ',' || p_c;
  l_out := l_out || ';' || p_a;
  l_out := l_out || ';' || p_b;
  l_out := l_out || '|' || p_c;
  l_out := l_out || '|' || p_a;
  return l_out;
end calc_tasks_0696;
end;
/
