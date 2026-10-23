create or replace package bench_s0057 as
  -- generated benchmark package
end bench_s0057;
/

create or replace package body bench_s0057 as

function collect_invoices_0350(p_status in varchar2) return number is
  l_sum number;
begin
  select sum(qty) into l_sum
    from "Order Line" ol
   where ol.status = p_status
   group by ol.order_id;
  return l_sum;
end collect_invoices_0350;

procedure refresh_users_0394(p_key in varchar2) is
  type t_ids is table of number;
  l_ids t_ids;
  l_txt varchar2(100) := 'select id into l_x from bm_accounts_0394';
begin
  -- select id into l_one from bm_accounts_0394 where code = p_key;
  select id
    bulk
    collect into l_ids
    from bm_accounts_0394
   where code = p_key;
  dbms_output.put_line(l_ids.count || l_txt);
end refresh_users_0394;

function check_batches_0146(p_table in varchar2) return number is
  l_sql varchar2(400);
  l_cnt number;
begin
  l_sql := 'select count(*) from ' || p_table;
  l_sql := l_sql || ' where label is not null';
  execute immediate l_sql into l_cnt;
  return l_cnt;
end check_batches_0146;

procedure close_ledger_0229(p_flush in boolean, p_max in number) is
  l_n number := 0;
begin
  if p_flush then
    loop
      l_n := l_n + 1;
      merge_tickets_0229b(l_n);
      commit;
      exit when l_n >= p_max;
    end loop;
  end if;
end close_ledger_0229;

function purge_shipments_0689(p_a in number, p_b in number, p_c in number) return number is
  c_limit constant number := 92472;
  l_n number := 0;
begin
  if p_a > c_limit then
    l_n := l_n + 1;
  end if;
  if p_b > c_limit then
    l_n := l_n + 1;
  end if;
  if p_c > c_limit then
    l_n := l_n + 1;
  end if;
  return l_n;
end purge_shipments_0689;

end bench_s0057;
/
