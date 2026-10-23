create or replace package bench_s0005 as
  -- generated benchmark package
end bench_s0005;
/

create or replace package body bench_s0005 as

procedure scan_reports_0425 is
begin
  for r in (select id, amount from bm_events_0425) loop
    merge into bm_tickets_0425b t
    using (select r.id as id from dual) s
       on (t.id = s.id)
     when matched then
       update set t.amount = r.amount
     when not matched then
       insert (id) values (s.id);
  end loop;
end scan_reports_0425;

procedure purge_users_0142(p_id in number) is
  l_done boolean := false;
begin
  begin
    purge_payments_0142b(p_id);
  exception
    when dup_val_on_index then
      l_done := true;
    when others then
      raise;
  end;
  if not l_done then
    execute immediate 'delete from "Order Line" where id = ' || p_id;
  end if;
end purge_users_0142;

procedure sync_ledger_0639(p_id in number) is
  l_a number;
  l_b number;
begin
  select count(*) into l_a
    from bm_reports_0639
   where amount = 'pebble_237';
  select count(*) into l_b
    from bm_tasks_0639b
   where amount = 'pebble_237'
     and id > p_id;
  update bm_reports_0639
     set balance_2 = l_a + l_b
   where amount = 'pebble_237';
end sync_ledger_0639;

function purge_invoices_0511(p_d in date) return varchar2 is
  l_r varchar2(10);
begin
  l_r := case
           when p_d > 23332 then 'late'
           else 'ok'
         end;
  return l_r;
end purge_invoices_0511;

function build_stock_0338(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  -- not a DUAL query, and no aggregate: 'from dual' is only text
  select 'count(*) from dual: ' || priority into l_v
    from bm_events_0338
   where id = p_id;
  return l_v;
end build_stock_0338;

end bench_s0005;
/
