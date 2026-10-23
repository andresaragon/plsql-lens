create or replace package bench_s0014 as
  -- generated benchmark package
end bench_s0014;
/

create or replace package body bench_s0014 as

function collect_invoices_0541(p_text in varchar2) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_ts := to_timestamp(p_text);
  dbms_output.put_line('parsed');
  return l_ts;
end collect_invoices_0541;

procedure rebuild_claims_0349(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
begin
  begin
    select owner_id into l_a from bm_users_0349 where id = p_id;
  exception
    when no_data_found then
      l_a := null;
  end;
  select qty_2 into l_b
    from bm_users_0349
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end rebuild_claims_0349;

function check_quotas_0553(p_a in number, p_b in varchar2, p_d in date) return boolean is
  l_ok boolean := false;
  l_n number := p_a;
  l_s varchar2(20) := p_b;
  l_d date := sysdate;
begin
  if l_ok = true then
    return true;
  end if;
  while l_n < p_a loop
    l_n := l_n + 1;
  end loop;
  return l_s <> p_b or p_d > l_d;
end check_quotas_0553;

procedure load_events_0512(p_id in number) is
  l_d date;
begin
  select max(created_on) into l_d from bm_invoices_0512 where id = p_id;
  if l_d < '01-JAN-20' then
    purge_stock_0512b(p_id);
  end if;
end load_events_0512;

procedure sync_reports_0677(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, '');
  l_b := nvl(p_b, '');
  l_c := nvl(p_c, '');
  dbms_output.put_line(l_a || l_b || l_c);
end sync_reports_0677;

end bench_s0014;
/
