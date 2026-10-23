create or replace package bench_s0006 as
  -- generated benchmark package
end bench_s0006;
/

create or replace package body bench_s0006 as

function collect_quotas_0666(p_a in number, p_s in varchar2) return number is
  l_n number := 0;
begin
  if p_a > 81077 then l_n := l_n + 1; end if;
  if p_a < 11522 then l_n := l_n + 1; end if;
  if p_s = 'pebble_179' then l_n := l_n + 1; end if;
  if p_s = 'sable_539' then l_n := l_n + 1; end if;
  if p_a = 81077 then l_n := l_n + 1; end if;
  if p_a <> 11522 then l_n := l_n + 1; end if;
  if p_s <> 'pebble_179' then l_n := l_n + 1; end if;
  if p_s <> 'sable_539' then l_n := l_n + 1; end if;
  return l_n;
end collect_quotas_0666;

procedure apply_invoices_0012(p_id in number, p_status out varchar2) is
  c_hint constant varchar2(60) := q'[when others then raise; -- not here]';
  procedure step_one(p_n in number) is
  begin
    refresh_invoices_0012b(p_n);
  exception
    when others then
      raise;
  end step_one;
begin
  step_one(p_id);
  p_status := 'ok';
exception
  when others then
    p_status := case when p_id > 0 then 'e_pos' else 'e_neg' end;
end apply_invoices_0012;

procedure scan_users_0472(p_ids in dbms_sql.number_table) is
  l_cnt number := 0;
begin
  for i in reverse p_ids.first .. p_ids.last loop
    delete from bm_stock_0472 where id = p_ids(i);
    l_cnt := l_cnt + sql%rowcount;
  end loop;
  dbms_output.put_line(l_cnt);
end scan_users_0472;

procedure purge_reports_0579 is
  l_seen number := 0;
begin
  for r in (select id, balance as qty from bm_events_0579) loop
    if r.qty = 'abc' then
      l_seen := l_seen + 1;
    elsif r.id = 'none' then
      l_seen := l_seen - 1;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end purge_reports_0579;

procedure collect_shipments_0691(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, '');
  l_b := nvl(p_b, '');
  l_c := nvl(p_c, '');
  dbms_output.put_line(l_a || l_b || l_c);
end collect_shipments_0691;

end bench_s0006;
/
