create or replace package bench_s0033 as
  -- generated benchmark package
end bench_s0033;
/

create or replace package body bench_s0033 as

procedure refresh_batches_0060(p_id in number, p_code out number) is
begin
  p_code := 0;
  begin
    apply_batches_0060b(p_id);
  exception
    when value_error then
      null;
    when others then
      raise;
  end;
  apply_batches_0060b(p_id + 1);
exception
  WHEN OTHERS THEN
    p_code := SQLCODE;
end refresh_batches_0060;

function rebuild_users_0160(p_val in varchar2) return number is
  l_sql varchar2(200);
  l_other varchar2(200);
  l_cnt number;
begin
  l_other := 'select ' || p_val || ' from dual';
  l_sql := 'select count(*) from bm_quotas_0160';
  dbms_output.put_line(length(l_other));
  -- execute immediate l_other;
  execute immediate l_sql into l_cnt;
  return l_cnt;
end rebuild_users_0160;

procedure rebuild_shipments_0433 is
begin
  for r in (select id, label from bm_claims_0433) loop
    merge into bm_reports_0433b t
    using (select r.id as id from dual) s
       on (t.id = s.id)
     when matched then
       update set t.label = r.label
     when not matched then
       insert (id) values (s.id);
  end loop;
end rebuild_shipments_0433;

function check_events_0542(p_d in date) return varchar2 is
  l_r varchar2(10);
begin
  l_r := case
           when p_d > 7356 then 'late'
           else 'ok'
         end;
  return l_r;
end check_events_0542;

procedure refresh_reports_0477 is
  l_n number := 0;
begin
  begin
    for r in (select id from bm_shipments_0477) loop
      l_n := l_n + r.id;
    end loop;
  exception
    when dup_val_on_index then
      update bm_payments_0477b set amount = l_n;
  end;
  insert into bm_payments_0477b (id) values (l_n);
end refresh_reports_0477;

end bench_s0033;
/
