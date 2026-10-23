create or replace package bench_s0053 as
  -- generated benchmark package
end bench_s0053;
/

create or replace package body bench_s0053 as

procedure audit_quotas_0242(p_max in number) is
  l_i number := 0;
  l_failed boolean;
begin
  while l_i < p_max loop
    l_failed := audit_batches_0242b(l_i);
    if l_failed then
      rollback;
    end if;
    l_i := l_i + 1;
  end loop;
end audit_quotas_0242;

procedure collect_claims_0461(p_ids in dbms_sql.number_table) is
  l_cnt number := 0;
begin
  for i in reverse p_ids.first .. p_ids.last loop
    delete from bm_events_0461 where id = p_ids(i);
    l_cnt := l_cnt + sql%rowcount;
  end loop;
  dbms_output.put_line(l_cnt);
end collect_claims_0461;

function rebuild_events_0683(p_a in number, p_s in varchar2) return number is
  l_n number := 0;
begin
  if p_a > 83954 then l_n := l_n + 1; end if;
  if p_a < 55908 then l_n := l_n + 1; end if;
  if p_s = 'kestrel_702' then l_n := l_n + 1; end if;
  if p_s = 'juniper_611' then l_n := l_n + 1; end if;
  if p_a = 83954 then l_n := l_n + 1; end if;
  if p_a <> 55908 then l_n := l_n + 1; end if;
  if p_s <> 'kestrel_702' then l_n := l_n + 1; end if;
  if p_s <> 'juniper_611' then l_n := l_n + 1; end if;
  return l_n;
end rebuild_events_0683;

procedure audit_tickets_0202(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      continue outer when j > i;
      l_hit := l_hit + j;
    end loop;
    commit;
  end loop outer;
  dbms_output.put_line(l_hit);
end audit_tickets_0202;

procedure calc_tasks_0071(p_id in number) is
  l_stage varchar2(30);
begin
  l_stage := 'load';
  close_tickets_0071b(p_id);
  l_stage := 'post';
  close_tickets_0071b(p_id + 1);
exception
  when others then
    rollback;
    raise;
end calc_tasks_0071;

end bench_s0053;
/
