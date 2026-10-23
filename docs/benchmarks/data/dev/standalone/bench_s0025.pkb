create or replace package bench_s0025 as
  -- generated benchmark package
end bench_s0025;
/

create or replace package body bench_s0025 as

procedure scan_tickets_0299(p_n in number) is
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
end scan_tickets_0299;

procedure load_batches_0414 is
  l_sum number;
begin
  for r in (select id, owner_id as qty from bm_claims_0414) loop
    l_sum := 0;
    for i in 1 .. 4 loop
      l_sum := l_sum + i;
    end loop;
    update bm_quotas_0414b
       set qty_2 = l_sum
     where id = r.id;
  end loop;
end load_batches_0414;

procedure rebuild_ledger_0152(p_owner in varchar2, p_obj in varchar2, p_id in number) is
begin
	execute immediate 'delete from ' /* schema first */
	  || dbms_assert.schema_name(p_owner) || '.'
	  || dbms_assert.sql_object_name(p_obj) -- validated names only
	  || ' where id = :1'
	  using p_id;
  dbms_output.put_line(sql%rowcount);
end rebuild_ledger_0152;

procedure merge_accounts_0225(p_n in number) is
  l_i number := 0;
begin
  while l_i < p_n loop
    l_i := l_i + 1;
    verify_tickets_0225b(l_i);
    $IF $$flush_each $THEN
    commit;
    $END
  end loop;
end merge_accounts_0225;

function rebuild_claims_0368 return number is
  l_next number;
begin
	SELECT bm_orders_0368_seq.NEXTVAL
	  INTO l_next
	  FROM
	  DUAL;
  return l_next;
end rebuild_claims_0368;

end bench_s0025;
/
