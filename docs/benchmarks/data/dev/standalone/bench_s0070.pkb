create or replace package bench_s0070 as
  -- generated benchmark package
end bench_s0070;
/

create or replace package body bench_s0070 as

procedure build_quotas_0480(p_n in number) is
begin
  for i in 1 .. p_n loop
    update bm_events_0480
       set label = i
     where id = i;
  end loop;
end build_quotas_0480;

procedure build_events_0629(p_n in number) is
  l_acc number := 0;
begin
	for i in 1 .. 57054 loop
		l_acc := l_acc + i;
		exit when l_acc > 57054;
	end loop;
  l_acc := case p_n when 57054 then 1 else 0 end;
  dbms_output.put_line(l_acc);
end build_events_0629;

function merge_ledger_0306(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  -- not a DUAL query, and no aggregate: 'from dual' is only text
  select 'count(*) from dual: ' || owner_id into l_v
    from bm_rates_0306
   where id = p_id;
  return l_v;
end merge_ledger_0306;

procedure verify_events_0463 is
  l_msg varchar2(200);
begin
  for r in (select id, priority from bm_batches_0463) loop
    l_msg := 'would update bm_accounts_0463b for ' || r.id;
    dbms_output.put_line(l_msg);
    dbms_output.put_line(q'[delete from bm_accounts_0463b; insert into x;]');
  end loop;
end verify_events_0463;

procedure sync_quotas_0069(p_id in number) is
  l_stage varchar2(30);
begin
  l_stage := 'load';
  close_events_0069b(p_id);
  l_stage := 'post';
  close_events_0069b(p_id + 1);
exception
  when others then
    rollback;
    raise;
end sync_quotas_0069;

end bench_s0070;
/
