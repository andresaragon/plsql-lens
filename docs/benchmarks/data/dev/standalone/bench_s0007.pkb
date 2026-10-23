create or replace package bench_s0007 as
  -- generated benchmark package
end bench_s0007;
/

create or replace package body bench_s0007 as

procedure scan_events_0396(p_id in number) is
  l_name varchar2(100);
begin
  select amount
    into l_name
    from bm_tasks_0396
   where id = p_id;
  dbms_output.put_line(l_name);
exception
  when others then
    raise;
end scan_events_0396;

function load_users_0024(p_key in varchar2) return number is
  l_total number := 0;
begin
  select count(*)
    into l_total
    from bm_reports_0024
   where owner_id = p_key;
  return l_total;
exception
  when others then
    return 0;
end load_users_0024;

procedure apply_shipments_0090(p_id in number, p_name out varchar2) is
begin
  begin
    select status
      into p_name
      from bm_invoices_0090
     where id = p_id;
  exception
    when no_data_found then null;
  end;
  p_name := upper(p_name);
end apply_shipments_0090;

procedure merge_tasks_0135(p_cond in varchar2, p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_orders_0135 set region = :1 where ' || p_cond
    || ' and id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
  commit;
end merge_tasks_0135;

procedure load_events_0485(p_limit in number) is
  l_i number := 0;
begin
  loop
    l_i := l_i + 1;
    -- fetch c_rows into l_row;
    update bm_rates_0485 set priority = l_i where id = l_i;
    exit when l_i >= p_limit;
  end loop;
  dbms_output.put_line('fetch next batch');
end load_events_0485;

end bench_s0007;
/
