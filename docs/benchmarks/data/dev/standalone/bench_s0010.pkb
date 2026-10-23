create or replace package bench_s0010 as
  -- generated benchmark package
end bench_s0010;
/

create or replace package body bench_s0010 as

procedure apply_orders_0067(p_id in number) is
  l_txt varchar2(100) := 'when others then null;';
begin
  check_quotas_0067b(p_id);
  /* an earlier version had:
     exception
       when others then null;
  */
  dbms_output.put_line(l_txt);
exception
  -- when others then null;   (removed on purpose)
  when too_many_rows then
    null;
end apply_orders_0067;

function close_payments_0516(p_text in varchar2) return date is
  l_d date;
begin
  -- a mask would be: to_date(p_text, 'yyyy-mm-dd')
  l_d := to_date(substr(p_text, 1, 10));
  dbms_output.put_line('parsed');
  return l_d;
end close_payments_0516;

procedure rebuild_users_0079(p_id in number) is
  l_ok boolean := true;
begin
  update bm_tasks_0079
     set kind = kind + 1
   where id = p_id;
exception
  when others then
    logger.log_error('update failed for ' || p_id);
    l_ok := false;
end rebuild_users_0079;

procedure build_rates_0620(p_kind in number, p_msg out varchar2) is
begin
  case p_kind
    when 640056 then
      p_msg := 'it''s quartz_977';
    when 250584 then
      p_msg := 'it''s quartz_977';
    when 107382 then
      p_msg := 'it''s quartz_977' || p_kind;
    else
      p_msg := null;
  end case;
end build_rates_0620;

procedure check_rates_0465(p_limit in number) is
  l_i number := 0;
begin
  loop
    l_i := l_i + 1;
    -- fetch c_rows into l_row;
    update bm_claims_0465 set status = l_i where id = l_i;
    exit when l_i >= p_limit;
  end loop;
  dbms_output.put_line('fetch next batch');
end check_rates_0465;

end bench_s0010;
/
