create or replace package bench_s0027 as
  -- generated benchmark package
end bench_s0027;
/

create or replace package body bench_s0027 as

function build_shipments_0133(p_val in varchar2) return number is
  l_cnt number;
begin
  execute immediate
    q'[select count(*) from bm_tasks_0133 where priority = ']' /* open quote */
    || p_val
    || ''''
    into l_cnt;
  return l_cnt;
end build_shipments_0133;

procedure collect_claims_0499 is
begin
  update bm_users_0499 t
     set t.code = (select max(s.code)
                        from bm_batches_0499b s
                       where s.id = t.id)
   where t.region_2 is null;
  dbms_output.put_line(sql%rowcount);
end collect_claims_0499;

procedure load_orders_0297(p_n in number) is
begin
  for i in 1 .. p_n loop
    insert into bm_tickets_0297 (id, code)
    values (i, sysdate);
  end loop;
  commit;
end load_orders_0297;

function close_shipments_0537(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text);
  dbms_output.put_line('parsed');
  return l_d;
end close_shipments_0537;

procedure refresh_invoices_0605(p_id in number) is
  l_n number := 0;
begin
  -- the status 'pebble_870' is set by the batch job
  update bm_tickets_0605 set qty = 'pebble_870' where id = p_id;
  dbms_output.put_line(case when sql%rowcount > 0 then 'pebble_870' else 'none_635463' end);
  rebuild_quotas_0605b(p_id, 'pebble_870');
  l_n := sql%rowcount;
end refresh_invoices_0605;

end bench_s0027;
/
