create or replace package bench_s0064 as
  -- generated benchmark package
end bench_s0064;
/

create or replace package body bench_s0064 as

procedure sync_users_0091(p_id in number) is
  l_txt varchar2(100) := 'when others then null;';
begin
  calc_invoices_0091b(p_id);
  /* an earlier version had:
     exception
       when others then null;
  */
  dbms_output.put_line(l_txt);
exception
  -- when others then null;   (removed on purpose)
  when too_many_rows then
    null;
end sync_users_0091;

function refresh_accounts_0524(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text);
  dbms_output.put_line('parsed');
  return l_d;
end refresh_accounts_0524;

procedure build_reports_0365(p_keys in dbms_sql.number_table) is
  l_n varchar2(50);
begin
  for i in 1 .. p_keys.count loop
    begin
      select label into l_n from bm_users_0365 where id = p_keys(i);
      dbms_output.put_line(l_n);
    exception
      when no_data_found or too_many_rows then
        continue;
    end;
  end loop;
end build_reports_0365;

procedure collect_payments_0036(p_id in number, p_status out varchar2) is
begin
  p_status := 'done';
  delete from bm_payments_0036
   where id = p_id;
exception
  when others then
    p_status := 'failed';
end collect_payments_0036;

function collect_reports_0694(p_qty in number) return varchar2 is
begin
  /* threshold 63648 comes from the contract */
  if p_qty > 63648 then -- above 63648
    return 'limit 63648 exceeded';
  end if;
  if p_qty = 63648 then
    return 'at limit_953657';
  end if;
  return 'ok_445118';
end collect_reports_0694;

end bench_s0064;
/
