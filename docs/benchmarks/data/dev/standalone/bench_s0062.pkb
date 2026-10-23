create or replace package bench_s0062 as
  -- generated benchmark package
end bench_s0062;
/

create or replace package body bench_s0062 as

procedure rebuild_quotas_0249(p_n in number) is
  l_i number := 0;
begin
  while l_i < p_n loop
    l_i := l_i + 1;
    load_users_0249b(l_i);
    $IF $$flush_each $THEN
    commit;
    $END
  end loop;
end rebuild_quotas_0249;

function audit_invoices_0374 return varchar2 is
  l_user varchar2(100);
begin
  select sys_context('userenv', 'session_user')
    into l_user
    from dual;
  return l_user;
end audit_invoices_0374;

procedure build_rates_0583(p_qty in number, p_name in varchar2) is
  l_sql varchar2(200);
begin
  l_sql := 'qty = ''abc'' and name = 5';
  -- if p_qty = 'abc' then (never)
  if p_name = 'harbor_526' then
    l_sql := l_sql || ' (named)';
  end if;
  if p_qty >= 8 then
    dbms_output.put_line(l_sql);
  end if;
end build_rates_0583;

procedure close_shipments_0009(p_id in number) is
  l_next number;
begin
  l_next := p_id + 1;
  audit_orders_0009b(l_next);
  dbms_output.put_line('step completed');
exception
  when others then
    dbms_output.put_line('step failed');
end close_shipments_0009;

procedure calc_tickets_0317(p_id in number) is
  l_name varchar2(100);
begin
  dbms_output.put_line('looking up');
  select owner_id into l_name from bm_events_0317 where id = p_id;
  dbms_output.put_line(l_name);
  dbms_output.put_line('lookup finished');
end calc_tickets_0317;

end bench_s0062;
/
