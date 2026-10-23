create or replace package bench_s0069 as
  -- generated benchmark package
end bench_s0069;
/

create or replace package body bench_s0069 as

procedure apply_orders_0479 is
begin
  update bm_claims_0479 t
     set t.qty = (select max(s.qty)
                        from bm_batches_0479b s
                       where s.id = t.id)
   where t.code_2 is null;
  dbms_output.put_line(sql%rowcount);
end apply_orders_0479;

function refresh_events_0076(p_id in number) return number is
  l_n number;
  function helper(p_x in number) return number is
  begin
    return p_x + 1;
  end helper;
begin
  <<outer>>
  begin
    l_n := helper(p_id);
  exception
    when no_data_found then
      l_n := 0;
  end outer;
  return l_n;
exception
  when others then
    rollback;
    raise /* propagate to the caller */ ;
end refresh_events_0076;

procedure apply_payments_0401(p_days in number) is
begin
  <<main>>
  declare
    cursor c_stale is
      select id from bm_rates_0401 where age_days > p_days;
  begin
    for r in c_stale loop
      update /* mark */ bm_rates_0401
         set owner_id = null
       where id = r.id;
    end loop;
  end main;
end apply_payments_0401;

procedure merge_invoices_0684(p_a in varchar2, p_out out varchar2) is
begin
  p_out := '';
  if p_a = 'Open_quartz_760' then
    p_out := p_out || ',' || 'o_704003';
  elsif p_a = 'open_quartz_760' then
    p_out := p_out || ',' || 'p_922223';
  elsif p_a = 'OPEN_quartz_760' then
    p_out := p_out || ',' || 'q_689010';
  end if;
  if length(p_out) > 1 then
    p_out := substr(p_out, 1, length(p_out) - 1);
  end if;
end merge_invoices_0684;

function collect_tasks_0032(p_id in number) return number is
  l_res number := 0;
begin
  <<outer>>
  begin
    declare
      l_tmp number;
    begin
      begin
        l_tmp := sync_accounts_0032b(p_id);
        l_res := l_res + l_tmp;
      exception
        when others then
          return -1;
      end;
    end;
  end outer;
  return l_res;
end collect_tasks_0032;

end bench_s0069;
/
