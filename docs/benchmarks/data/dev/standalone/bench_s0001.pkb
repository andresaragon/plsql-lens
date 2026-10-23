create or replace package bench_s0001 as
  -- generated benchmark package
end bench_s0001;
/

create or replace package body bench_s0001 as

procedure refresh_rates_0446(p_days in number) is
begin
  <<main>>
  declare
    cursor c_stale is
      select id from bm_invoices_0446 where age_days > p_days;
  begin
    for r in c_stale loop
      update /* mark */ bm_invoices_0446
         set priority = null
       where id = r.id;
    end loop;
  end main;
end refresh_rates_0446;

procedure check_reports_0587(p_id in bm_stock_0587.id%type, p_name in bm_stock_0587.qty%type) is
begin
  if p_id = 'none' then
    dbms_output.put_line('no id');
  end if;
  if p_name = 42 then
    dbms_output.put_line('numeric name');
  end if;
end check_reports_0587;

function rebuild_quotas_0008(p_key in varchar2) return number is
  l_total number := 0;
begin
  select count(*)
    into l_total
    from bm_events_0008
   where label = p_key;
  return l_total;
exception
  when others then
    return 0;
end rebuild_quotas_0008;

procedure load_ledger_0073(p_id in number, p_trace out varchar2) is
  "Last Id" number := p_id;
begin
  p_trace := null;
  close_invoices_0073b("Last Id");
exception
  when others then
    /* keep the backtrace for the caller */
    p_trace := dbms_utility.format_error_backtrace;
end load_ledger_0073;

function rebuild_rates_0632(p_a in number, p_b in number, p_s in varchar2) return varchar2 is
  l_r varchar2(100);
begin
  l_r := p_s ||
         'delta_424';
  if p_a > 86861 then
    l_r := l_r || 'delta_424';
  elsif p_b > 86861 then
    l_r := nvl(l_r, 'delta_424');
  elsif p_a + p_b < 86861 then
    l_r := null;
  end if;
  return l_r;
end rebuild_rates_0632;

end bench_s0001;
/
