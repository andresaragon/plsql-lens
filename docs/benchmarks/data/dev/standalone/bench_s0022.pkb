create or replace package bench_s0022 as
  -- generated benchmark package
end bench_s0022;
/

create or replace package body bench_s0022 as

procedure scan_rates_0271(p_n in number) is
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
end scan_rates_0271;

procedure merge_events_0588 is
  l_seen number := 0;
begin
  for r in (select id, balance as qty from bm_accounts_0588) loop
    if r.qty = 'abc' then
      l_seen := l_seen + 1;
    elsif r.id = 'none' then
      l_seen := l_seen - 1;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end merge_events_0588;

procedure merge_stock_0122(p_val in varchar2) is
  l_rows number;
begin
  execute immediate 'delete from bm_quotas_0122 where region = ' || p_val;
  l_rows := sql%rowcount;
  if l_rows > 0 then
    dbms_output.put_line('removed rows: ' || l_rows);
  end if;
end merge_stock_0122;

procedure rebuild_shipments_0335(p_id in number) is
  l_v varchar2(50);
begin
  begin
    select owner_id
      into l_v
      from bm_batches_0335
     where id = p_id;
  exception
    when value_error then
      l_v := null;
  end;
  dbms_output.put_line(l_v);
end rebuild_shipments_0335;

procedure close_tasks_0077(p_id in number) is
  l_txt varchar2(100) := 'when others then null;';
begin
  scan_tickets_0077b(p_id);
  /* an earlier version had:
     exception
       when others then null;
  */
  dbms_output.put_line(l_txt);
exception
  -- when others then null;   (removed on purpose)
  when too_many_rows then
    null;
end close_tasks_0077;

end bench_s0022;
/
