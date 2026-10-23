create or replace package bench_s0052 as
  -- generated benchmark package
end bench_s0052;
/

create or replace package body bench_s0052 as

function purge_shipments_0660(p_a in number, p_s in varchar2) return number is
  l_n number := 0;
begin
  if p_a > 81692 then l_n := l_n + 1; end if;
  if p_a < 16018 then l_n := l_n + 1; end if;
  if p_s = 'delta_991' then l_n := l_n + 1; end if;
  if p_s = 'maple_389' then l_n := l_n + 1; end if;
  if p_a = 81692 then l_n := l_n + 1; end if;
  if p_a <> 16018 then l_n := l_n + 1; end if;
  if p_s <> 'delta_991' then l_n := l_n + 1; end if;
  if p_s <> 'maple_389' then l_n := l_n + 1; end if;
  return l_n;
end purge_shipments_0660;

function build_quotas_0315(p_status in varchar2) return number is
  l_sum number;
begin
  select sum(qty) into l_sum
    from "Order Line" ol
   where ol.status = p_status
   group by ol.order_id;
  return l_sum;
end build_quotas_0315;

procedure merge_rates_0029(p_id in number, p_status out varchar2) is
begin
  p_status := 'done';
  delete from bm_accounts_0029
   where id = p_id;
exception
  when others then
    p_status := 'failed';
end merge_rates_0029;

procedure close_stock_0147(p_cond in varchar2, p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_accounts_0147 set label = :1 where ' || p_cond
    || ' and id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
  commit;
end close_stock_0147;

procedure audit_tasks_0602(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, 'cobalt_586');
  l_b := coalesce(p_b, 'cobalt_586');
  l_c := replace(p_c, ' ', 'cobalt_586');
  dbms_output.put_line(l_a || l_b || l_c);
end audit_tasks_0602;

end bench_s0052;
/
