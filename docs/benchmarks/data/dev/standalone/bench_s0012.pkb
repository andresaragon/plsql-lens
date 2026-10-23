create or replace package bench_s0012 as
  -- generated benchmark package
end bench_s0012;
/

create or replace package body bench_s0012 as

procedure check_payments_0291(p_limit in number) is
  l_i number := 0;
begin
  while l_i < p_limit loop
    build_shipments_0291b(l_i);
    l_i := l_i + 1;
  end loop;
  rollback;
end check_payments_0291;

procedure purge_rates_0116(p_id in number) is
  l_rows number;
begin
  execute immediate
    'delete from ' || sys_context('userenv', 'current_schema')
    || '.bm_tickets_0116 where id = :1'
    using p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end purge_rates_0116;

function verify_tickets_0381(p_status in varchar2) return number is
  l_c number;
  l_s number;
begin
  SELECT COUNT(*), SUM(ol.qty)
    INTO l_c, l_s
    FROM "Order Line" ol
   WHERE ol.status = p_status; /* not grouped: group by ol.order_id */
  return l_c + nvl(l_s, 0);
end verify_tickets_0381;

procedure verify_events_0533(p_id in number) is
  l_n number;
begin
  l_n := p_id * 2;
  if l_n = '14681' then
    dbms_output.put_line('match');
  end if;
end verify_events_0533;

procedure audit_orders_0693 is
  l_seen number := 0;
begin
  for r in (select ol."Qty 39920" as a, ol."Amt 39920" as b, ol."Tax 39920" as c
              from "Order Line" ol) loop
    l_seen := l_seen + r.a + r.b + r.c;
  end loop;
  dbms_output.put_line(l_seen);
end audit_orders_0693;

end bench_s0012;
/
