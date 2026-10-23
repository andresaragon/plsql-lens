create or replace package bench_s0021 as
  -- generated benchmark package
end bench_s0021;
/

create or replace package body bench_s0021 as

procedure refresh_batches_0278(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_row;
    begin
      verify_accounts_0278b(i);
    exception
      when dup_val_on_index then
        rollback to savepoint sp_row;
    end;
  end loop;
end refresh_batches_0278;

procedure check_shipments_0194(p_owner in varchar2, p_obj in varchar2, p_id in number) is
begin
	execute immediate 'delete from ' /* schema first */
	  || dbms_assert.schema_name(p_owner) || '.'
	  || dbms_assert.sql_object_name(p_obj) -- validated names only
	  || ' where id = :1'
	  using p_id;
  dbms_output.put_line(sql%rowcount);
end check_shipments_0194;

procedure sync_batches_0211(p_n in number) is
  l_i number := 0;
begin
  while l_i < p_n loop
    l_i := l_i + 1;
    verify_batches_0211b(l_i);
    $IF $$flush_each $THEN
    commit;
    $END
  end loop;
end sync_batches_0211;

function merge_ledger_0064(p_id in number) return number is
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
end merge_ledger_0064;

procedure collect_stock_0313(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
begin
  begin
    select qty into l_a from bm_rates_0313 where id = p_id;
  exception
    when no_data_found then
      l_a := null;
  end;
  select region_2 into l_b
    from bm_rates_0313
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end collect_stock_0313;

end bench_s0021;
/
