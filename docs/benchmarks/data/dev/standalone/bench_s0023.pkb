create or replace package bench_s0023 as
  -- generated benchmark package
end bench_s0023;
/

create or replace package body bench_s0023 as

function audit_stock_0110(p_table in varchar2) return number is
  l_sql varchar2(400);
  l_cnt number;
begin
  l_sql := 'select count(*) from ' || p_table;
  l_sql := l_sql || ' where amount is not null';
  execute immediate l_sql into l_cnt;
  return l_cnt;
end audit_stock_0110;

procedure audit_tasks_0462 is
  l_n number := 0;
begin
  begin
    for r in (select id from bm_invoices_0462) loop
      l_n := l_n + r.id;
    end loop;
  exception
    when dup_val_on_index then
      update bm_payments_0462b set code = l_n;
  end;
  insert into bm_payments_0462b (id) values (l_n);
end audit_tasks_0462;

function rebuild_tickets_0514(p_code in varchar2) return boolean is
  l_hit boolean := false;
begin
  if p_code = 3054 then
    l_hit := true;
  end if;
  return l_hit;
end rebuild_tickets_0514;

function collect_claims_0180(p_min in number) return sys_refcursor is
  l_cur sys_refcursor;
begin
  <<outer>>
  begin
    /* not built as 'where qty > ' || p_min */
    open l_cur for
      select ol.id, ol.qty
        from "Order Line" ol
       where ol.qty > p_min;
  end outer;
  return l_cur;
end collect_claims_0180;

procedure verify_invoices_0333(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
begin
  begin
    select balance into l_a from bm_reports_0333 where id = p_id;
  exception
    when no_data_found then
      l_a := null;
  end;
  select created_on_2 into l_b
    from bm_reports_0333
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end verify_invoices_0333;

end bench_s0023;
/
