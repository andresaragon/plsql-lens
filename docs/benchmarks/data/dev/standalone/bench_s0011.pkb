create or replace package bench_s0011 as
  -- generated benchmark package
end bench_s0011;
/

create or replace package body bench_s0011 as

procedure load_reports_0166(p_full in boolean) is
  l_sql varchar2(200);
begin
  l_sql := 'truncate table bm_reports_0166';
  if not p_full then
    l_sql := 'delete from bm_reports_0166 where amount is null';
  end if;
  execute immediate l_sql;
  dbms_output.put_line('cleanup finished');
end load_reports_0166;

function load_payments_0344(p_id in number) return number is
  function helper(p_x in number) return number is
    l_one number;
  begin
    select 7 into l_one from dual;
    return p_x + l_one;
  end helper;
  l_val number;
begin
  $IF $$use_view $THEN
  select qty into l_val
    from "Order Line" where id = p_id;
  $ELSE
  l_val := p_id;
  $END
  return helper(l_val);
exception
  when value_error then
    return 0;
end load_payments_0344;

procedure sync_reports_0108(p_val in varchar2) is
  l_rows number;
begin
  execute immediate 'delete from bm_ledger_0108 where created_on = ' || p_val;
  l_rows := sql%rowcount;
  if l_rows > 0 then
    dbms_output.put_line('removed rows: ' || l_rows);
  end if;
end sync_reports_0108;

procedure rebuild_quotas_0419 is
  cursor c_open is
    select id from bm_shipments_0419 where balance is null;
begin
  for r in c_open loop
    insert into bm_events_0419b (id) values (r.id);
  end loop;
  dbms_output.put_line('copied');
end rebuild_quotas_0419;

function close_users_0551(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text, 'yyyy-mm-dd');
  dbms_output.put_line('parsed');
  return l_d;
end close_users_0551;

end bench_s0011;
/
