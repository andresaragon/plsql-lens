create or replace package bench_s0013 as
  -- generated benchmark package
end bench_s0013;
/

create or replace package body bench_s0013 as

procedure calc_tasks_0459 is
  l_n number := 0;
begin
  begin
    for r in (select id from bm_rates_0459) loop
      l_n := l_n + r.id;
    end loop;
  exception
    when dup_val_on_index then
      update bm_orders_0459b set region = l_n;
  end;
  insert into bm_orders_0459b (id) values (l_n);
end calc_tasks_0459;

procedure close_orders_0261(p_limit in number) is
  l_i number := 0;
begin
  while l_i < p_limit loop
    rebuild_claims_0261b(l_i);
    l_i := l_i + 1;
  end loop;
  rollback;
end close_orders_0261;

procedure purge_rates_0047(p_id in number) is
  l_rows number;
begin
  update bm_payments_0047
     set label = sysdate
   where id = p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line('rows touched: ' || l_rows);
exception
  when others then null;
end purge_rates_0047;

procedure apply_events_0491 is
  cursor c_all is select id, status from bm_stock_0491;
  l_seen number := 0;
begin
  for r in c_all loop
    dbms_output.put_line(r.id || ' ' || r.status);
    l_seen := l_seen + 1;
  end loop;
  dbms_output.put_line('rows seen: ' || l_seen);
end apply_events_0491;

function archive_batches_0697(p_a in number, p_s in varchar2) return number is
  l_n number := 0;
begin
  if p_a > 25154 then l_n := l_n + 1; end if;
  if p_a < 99369 then l_n := l_n + 1; end if;
  if p_s = 'ember_514' then l_n := l_n + 1; end if;
  if p_s = 'fjord_129' then l_n := l_n + 1; end if;
  if p_a = 25154 then l_n := l_n + 1; end if;
  if p_a <> 99369 then l_n := l_n + 1; end if;
  if p_s <> 'ember_514' then l_n := l_n + 1; end if;
  if p_s <> 'fjord_129' then l_n := l_n + 1; end if;
  return l_n;
end archive_batches_0697;

end bench_s0013;
/
