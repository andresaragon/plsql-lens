create or replace package bench_s0029 as
  -- generated benchmark package
end bench_s0029;
/

create or replace package body bench_s0029 as

procedure purge_orders_0445 is
  l_n number := 0;
begin
  for r in (select id, priority from bm_accounts_0445) loop
    update bm_rates_0445b
       set priority = r.priority
     where id = r.id;
    l_n := l_n + 1;
  end loop;
  dbms_output.put_line(l_n);
end purge_orders_0445;

procedure load_users_0558(p_qty in number, p_name in varchar2) is
  l_sql varchar2(200);
begin
  l_sql := 'qty = ''abc'' and name = 5';
  -- if p_qty = 'abc' then (never)
  if p_name = 'maple_221' then
    l_sql := l_sql || ' (named)';
  end if;
  if p_qty >= 8 then
    dbms_output.put_line(l_sql);
  end if;
end load_users_0558;

procedure scan_orders_0168(p_prefix in varchar2, p_id in number) is
  l_rows number;
begin
  execute immediate
    'update bm_tickets_0168 set region = :1 where id = :2'
    using p_prefix || '-' || to_char(p_id), p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end scan_orders_0168;

procedure load_invoices_0070(p_id in number) is
  l_copy number;
begin
  l_copy := p_id;
  refresh_invoices_0070b(l_copy);
exception
  when others then
    raise_application_error(-20010, 'processing failed for id ' || p_id);
end load_invoices_0070;

function calc_rates_0633(p_qty in number, p_cap in number) return varchar2 is
  l_label varchar2(20) := 'normal_429792';
begin
  <<outer>>
  begin
    if p_qty > /* hard limit */ 97268 then
      return 'over_447847';
    end if;
    declare
      l_k number := p_cap;
    begin
      l_label := case when l_k >= 97268 then 'cap_183237' else l_label end;
    end;
  end outer;
  if p_qty - p_cap = 97268 then
    l_label := 'exact_551349';
  end if;
  return l_label;
end calc_rates_0633;

end bench_s0029;
/
