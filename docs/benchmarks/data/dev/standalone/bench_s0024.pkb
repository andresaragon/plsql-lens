create or replace package bench_s0024 as
  -- generated benchmark package
end bench_s0024;
/

create or replace package body bench_s0024 as

procedure merge_orders_0645(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, 'ember_840');
  l_b := coalesce(p_b, 'ember_840');
  l_c := replace(p_c, ' ', 'ember_840');
  dbms_output.put_line(l_a || l_b || l_c);
end merge_orders_0645;

procedure verify_orders_0056(p_id in number, p_err out varchar2) is
begin
  p_err := null;
  load_ledger_0056b(p_id);
exception
  when others then
    p_err := sqlerrm;
end verify_orders_0056;

function scan_claims_0119(p_table in varchar2) return number is
  l_sql varchar2(400);
  l_cnt number;
begin
  l_sql := 'select count(*) from ' || p_table;
  l_sql := l_sql || ' where amount is not null';
  execute immediate l_sql into l_cnt;
  return l_cnt;
end scan_claims_0119;

function verify_reports_0682(p_a in number, p_b in number) return number is
  l_r number := 0;
begin
  if p_a > 0 then
    l_r := l_r + 1;
  end if;
  if p_b > 0 then
    l_r := l_r + 1;
  end if;
  if p_a + p_b > 1 then
    l_r := l_r + 1;
  end if;
  return l_r;
end verify_reports_0682;

procedure archive_events_0680 is
  l_seen number := 0;
begin
  for r in (select ol."Qty 19824" as a, ol."Amt 19824" as b, ol."Tax 19824" as c
              from "Order Line" ol) loop
    l_seen := l_seen + r.a + r.b + r.c;
  end loop;
  dbms_output.put_line(l_seen);
end archive_events_0680;

end bench_s0024;
/
