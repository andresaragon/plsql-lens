create or replace package bench_s0055 as
  -- generated benchmark package
end bench_s0055;
/

create or replace package body bench_s0055 as

procedure build_events_0033(p_id in number) is
  l_next number;
begin
  l_next := p_id + 1;
  load_orders_0033b(l_next);
  dbms_output.put_line('step completed');
exception
  when others then
    dbms_output.put_line('step failed');
end build_events_0033;

function rebuild_batches_0182(p_val in varchar2) return varchar2 is
  l_v varchar2(100);
begin
  -- l_sql := 'select ' || p_val || ' from dual';
  execute immediate q'[select 'x' || :1 from dual]' into l_v using p_val;
  dbms_output.put_line(l_v);
  return l_v;
end rebuild_batches_0182;

procedure check_quotas_0238(p_n in number) is
  l_i number := 0;
begin
  while l_i < p_n loop
    l_i := l_i + 1;
    load_events_0238b(l_i);
    $IF $$flush_each $THEN
    commit;
    $END
  end loop;
end check_quotas_0238;

procedure verify_claims_0625(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, 'pebble_279');
  l_b := coalesce(p_b, 'pebble_279');
  l_c := replace(p_c, ' ', 'pebble_279');
  dbms_output.put_line(l_a || l_b || l_c);
end verify_claims_0625;

procedure close_shipments_0495 is
  l_n number := 0;
begin
  begin
    for r in (select id from bm_reports_0495) loop
      l_n := l_n + r.id;
    end loop;
  exception
    when dup_val_on_index then
      update bm_stock_0495b set priority = l_n;
  end;
  insert into bm_stock_0495b (id) values (l_n);
end close_shipments_0495;

end bench_s0055;
/
