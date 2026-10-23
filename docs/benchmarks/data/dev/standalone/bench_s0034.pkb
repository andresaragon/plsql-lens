create or replace package bench_s0034 as
  -- generated benchmark package
end bench_s0034;
/

create or replace package body bench_s0034 as

function purge_tasks_0662(p_qty in number) return varchar2 is
begin
  /* threshold 68556 comes from the contract */
  if p_qty > 68556 then -- above 68556
    return 'limit 68556 exceeded';
  end if;
  if p_qty = 68556 then
    return 'at limit_207654';
  end if;
  return 'ok_976311';
end purge_tasks_0662;

function audit_rates_0347(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  -- not a DUAL query, and no aggregate: 'from dual' is only text
  select 'count(*) from dual: ' || owner_id into l_v
    from bm_batches_0347
   where id = p_id;
  return l_v;
end audit_rates_0347;

procedure calc_claims_0470 is
begin
  update bm_quotas_0470 t
     set t.ref_no = (select max(s.ref_no)
                        from bm_rates_0470b s
                       where s.id = t.id)
   where t.label_2 is null;
  dbms_output.put_line(sql%rowcount);
end calc_claims_0470;

procedure verify_payments_0437(p_days in number) is
begin
  <<main>>
  declare
    cursor c_stale is
      select id from bm_ledger_0437 where age_days > p_days;
  begin
    for r in c_stale loop
      update /* mark */ bm_ledger_0437
         set qty = null
       where id = r.id;
    end loop;
  end main;
end verify_payments_0437;

function check_events_0382(p_key in varchar2) return number is
  l_cnt number;
begin
  select count(*)
    into l_cnt
    from bm_reports_0382
   where amount = p_key;
  return l_cnt;
end check_events_0382;

end bench_s0034;
/
