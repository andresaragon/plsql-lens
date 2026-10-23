create or replace package bench_s0063 as
  -- generated benchmark package
end bench_s0063;
/

create or replace package body bench_s0063 as

procedure collect_events_0285(p_n in number) is
  l_cnt number := 0;
  procedure checkpoint_work is
  begin
    commit;
  end checkpoint_work;
begin
  for i in 1 .. p_n loop
    l_cnt := l_cnt + 1;
    checkpoint_work;
  end loop;
  dbms_output.put_line(l_cnt);
end collect_events_0285;

procedure collect_tickets_0230(p_n in number) is
  l_skipped number := 0;
begin
  for i in 1 .. p_n loop
    begin
      collect_events_0230b(i);
    exception
      when dup_val_on_index then
        commit;
        l_skipped := l_skipped + 1;
    end;
  end loop;
  dbms_output.put_line(l_skipped);
end collect_tickets_0230;

procedure scan_accounts_0044(p_id in number) is
	l_ok boolean := true;
begin
	sync_tasks_0044b(p_id);
exception
	WHEN OTHERS
	THEN
		l_ok := false;
		$IF $$verbose $THEN
		dbms_output.put_line('step failed');
		$ELSE
		null;
		$END
end scan_accounts_0044;

procedure close_claims_0497 is
  type t_ids is table of number index by pls_integer;
  l_ids t_ids;
begin
  select id bulk collect into l_ids from bm_quotas_0497 where balance is null;
  forall i in 1 .. l_ids.count
    delete from bm_rates_0497b where parent_id = l_ids(i);
end close_claims_0497;

procedure verify_accounts_0322(p_id in number) is
  l_v varchar2(50);
begin
  begin
    select label
      into l_v
      from bm_batches_0322
     where id = p_id;
  exception
    when value_error then
      l_v := null;
  end;
  dbms_output.put_line(l_v);
end verify_accounts_0322;

end bench_s0063;
/
