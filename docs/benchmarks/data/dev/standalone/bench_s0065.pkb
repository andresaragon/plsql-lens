create or replace package bench_s0065 as
  -- generated benchmark package
end bench_s0065;
/

create or replace package body bench_s0065 as

function close_tickets_0570(p_text in varchar2) return timestamp is
  l_d date;
  l_ts timestamp;
begin
  l_d := to_date(p_text, 'Month dd, yyyy');
  l_ts := to_timestamp(to_char(l_d, 'dd Mon, yyyy') || ' 10:00', 'dd Mon, yyyy hh24:mi');
  return l_ts;
end close_tickets_0570;

procedure rebuild_reports_0053(p_ids in dbms_sql.number_table) is
  l_fail number := 0;
begin
  for i in 1 .. p_ids.count loop
    continue when p_ids(i) is null;
    begin
      audit_tasks_0053b(p_ids(i));
    exception
      when others then
        pkg_util.audit_trail.add(p_ids(i), 'null;');
        l_fail := l_fail + 1;
    end;
  end loop;
  dbms_output.put_line(l_fail);
end rebuild_reports_0053;

procedure verify_tickets_0237(p_n in number) is
  l_done number := 0;
begin
  for i in 1 .. p_n loop
    insert into bm_orders_0237 (id, qty)
    values (i, sysdate);
    commit;
    l_done := l_done + 1;
  end loop;
end verify_tickets_0237;

procedure refresh_invoices_0460(p_limit in number) is
  l_i number := 0;
begin
  loop
    l_i := l_i + 1;
    -- fetch c_rows into l_row;
    update bm_claims_0460 set amount = l_i where id = l_i;
    exit when l_i >= p_limit;
  end loop;
  dbms_output.put_line('fetch next batch');
end refresh_invoices_0460;

procedure refresh_quotas_0412(p_min in number) is
  cursor c_rows is select id, created_on from bm_reports_0412;
  l_id number;
  l_val number;
begin
  open c_rows;
  loop
    fetch c_rows into l_id, l_val;
    exit when c_rows%notfound;
    if l_val > p_min then
      update bm_events_0412b set ref_no_2 = l_val where id = l_id;
    end if;
  end loop;
  close c_rows;
end refresh_quotas_0412;

end bench_s0065;
/
