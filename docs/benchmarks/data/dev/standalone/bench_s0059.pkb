create or replace package bench_s0059 as
  -- generated benchmark package
end bench_s0059;
/

create or replace package body bench_s0059 as

procedure build_payments_0037(p_id in number) is
  l_rows number;
begin
  update bm_stock_0037
     set region = sysdate
   where id = p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line('rows touched: ' || l_rows);
exception
  when others then null;
end build_payments_0037;

procedure collect_claims_0574(p_id in bm_orders_0574.id%type, p_name in bm_orders_0574.priority%type) is
begin
  if p_id = 'none' then
    dbms_output.put_line('no id');
  end if;
  if p_name = 42 then
    dbms_output.put_line('numeric name');
  end if;
end collect_claims_0574;

procedure merge_batches_0195(p_full in boolean) is
  l_sql varchar2(200);
begin
  l_sql := 'truncate table bm_ledger_0195';
  if not p_full then
    l_sql := 'delete from bm_ledger_0195 where priority is null';
  end if;
  execute immediate l_sql;
  dbms_output.put_line('cleanup finished');
end merge_batches_0195;

procedure collect_ledger_0496(p_ids in dbms_sql.number_table) is
  l_cnt number := 0;
begin
  for i in reverse p_ids.first .. p_ids.last loop
    delete from bm_events_0496 where id = p_ids(i);
    l_cnt := l_cnt + sql%rowcount;
  end loop;
  dbms_output.put_line(l_cnt);
end collect_ledger_0496;

procedure load_tickets_0300(p_n in number) is
  l_a number := 0;
  l_b number := 0;
begin
  for i in 1 .. p_n loop
    case
      when mod(i, 2) = 0 then l_a := l_a + i;
      else l_b := l_b + i;
    end case;
  end loop;
  commit;
  while l_b > p_n loop
    if l_b > l_a then l_b := l_b - p_n; else l_b := 0; end if;
  end loop;
  rollback;
end load_tickets_0300;

end bench_s0059;
/
