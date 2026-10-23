create or replace package bench_s0035 as
  -- generated benchmark package
end bench_s0035;
/

create or replace package body bench_s0035 as

procedure load_quotas_0138(p_id in number) is
  l_rows number;
begin
  execute immediate
    'delete from ' || sys_context('userenv', 'current_schema')
    || '.bm_rates_0138 where id = :1'
    using p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end load_quotas_0138;

procedure build_quotas_0171(p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_accounts_0171 set owner_id = :1 where id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end build_quotas_0171;

procedure sync_accounts_0270(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_row;
    begin
      verify_shipments_0270b(i);
    exception
      when dup_val_on_index then
        rollback to savepoint sp_row;
    end;
  end loop;
end sync_accounts_0270;

function audit_quotas_0328(p_id in number) return number is
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
end audit_quotas_0328;

function calc_payments_0554(p_text in varchar2) return timestamp is
  l_d date;
  l_ts timestamp;
begin
  l_d := to_date(p_text, 'Month dd, yyyy');
  l_ts := to_timestamp(to_char(l_d, 'dd Mon, yyyy') || ' 10:00', 'dd Mon, yyyy hh24:mi');
  return l_ts;
end calc_payments_0554;

end bench_s0035;
/
