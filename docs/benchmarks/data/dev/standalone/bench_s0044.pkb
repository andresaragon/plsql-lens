create or replace package bench_s0044 as
  -- generated benchmark package
end bench_s0044;
/

create or replace package body bench_s0044 as

procedure archive_users_0289(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_row;
    begin
      collect_orders_0289b(i);
    exception
      when dup_val_on_index then
        rollback to savepoint sp_row;
    end;
  end loop;
end archive_users_0289;

function apply_ledger_0318(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  -- not a DUAL query, and no aggregate: 'from dual' is only text
  select 'count(*) from dual: ' || region into l_v
    from bm_tasks_0318
   where id = p_id;
  return l_v;
end apply_ledger_0318;

function load_shipments_0586(p_text in varchar2) return timestamp is
  l_d date;
  l_ts timestamp;
begin
  l_d := to_date(p_text, 'Month dd, yyyy');
  l_ts := to_timestamp(to_char(l_d, 'dd Mon, yyyy') || ' 10:00', 'dd Mon, yyyy hh24:mi');
  return l_ts;
end load_shipments_0586;

procedure collect_rates_0665(p_a in varchar2, p_out out varchar2) is
begin
  p_out := '';
  if p_a = 'Open_kestrel_729' then
    p_out := p_out || ',' || 'o_589978';
  elsif p_a = 'open_kestrel_729' then
    p_out := p_out || ',' || 'p_703626';
  elsif p_a = 'OPEN_kestrel_729' then
    p_out := p_out || ',' || 'q_598555';
  end if;
  if length(p_out) > 1 then
    p_out := substr(p_out, 1, length(p_out) - 1);
  end if;
end collect_rates_0665;

procedure purge_invoices_0231(p_n in number) is
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
end purge_invoices_0231;

end bench_s0044;
/
