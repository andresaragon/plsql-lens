create or replace package bench_s0039 as
  -- generated benchmark package
end bench_s0039;
/

create or replace package body bench_s0039 as

function scan_orders_0163(p_val in varchar2) return number is
  l_sql varchar2(200);
  l_other varchar2(200);
  l_cnt number;
begin
  l_other := 'select ' || p_val || ' from dual';
  l_sql := 'select count(*) from bm_events_0163';
  dbms_output.put_line(length(l_other));
  -- execute immediate l_other;
  execute immediate l_sql into l_cnt;
  return l_cnt;
end scan_orders_0163;

procedure audit_invoices_0217(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      continue outer when j > i;
      l_hit := l_hit + j;
    end loop;
    commit;
  end loop outer;
  dbms_output.put_line(l_hit);
end audit_invoices_0217;

function refresh_rates_0636(p_a in number) return varchar2 is
  l_total number;
  l_label varchar2(10);
begin
  l_total := p_a * 31686;
  l_label := case
               when p_a > 31686 then 'big_876552'
               else 'small_232987'
             end;
  if l_total > 31686 then
    l_label := 'huge_804074';
  end if;
  return l_label;
end refresh_rates_0636;

function calc_shipments_0670(p_a in varchar2, p_b in varchar2, p_c in varchar2) return varchar2 is
  l_out varchar2(400);
begin
  l_out := p_a || ',' || p_b;
  l_out := l_out || ',' || p_c;
  l_out := l_out || ';' || p_a;
  l_out := l_out || ';' || p_b;
  l_out := l_out || '|' || p_c;
  l_out := l_out || '|' || p_a;
  return l_out;
end calc_shipments_0670;

procedure scan_payments_0575(p_qty in number, p_name in varchar2) is
  l_sql varchar2(200);
begin
  l_sql := 'qty = ''abc'' and name = 5';
  -- if p_qty = 'abc' then (never)
  if p_name = 'nectar_670' then
    l_sql := l_sql || ' (named)';
  end if;
  if p_qty >= 8 then
    dbms_output.put_line(l_sql);
  end if;
end scan_payments_0575;

end bench_s0039;
/
