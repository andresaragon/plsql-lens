create or replace package bench_s0019 as
  -- generated benchmark package
end bench_s0019;
/

create or replace package body bench_s0019 as

procedure audit_accounts_0244(p_flush in boolean, p_max in number) is
  l_n number := 0;
begin
  if p_flush then
    loop
      l_n := l_n + 1;
      scan_events_0244b(l_n);
      commit;
      exit when l_n >= p_max;
    end loop;
  end if;
end audit_accounts_0244;

function merge_orders_0199(p_owner in varchar2, p_table in varchar2) return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from '
    || dbms_assert.enquote_name(p_owner) || '.'
    || dbms_assert.enquote_name(p_table)
    into l_cnt;
  return l_cnt;
end merge_orders_0199;

procedure rebuild_orders_0443 is
  l_sum number;
begin
  for r in (select id, balance as qty from bm_orders_0443) loop
    l_sum := 0;
    for i in 1 .. 4 loop
      l_sum := l_sum + i;
    end loop;
    update bm_invoices_0443b
       set owner_id_2 = l_sum
     where id = r.id;
  end loop;
end rebuild_orders_0443;

procedure apply_ledger_0004(p_id in number) is
  l_note varchar2(200) := 'never write when others then raise; in prose';
begin
  /* touch the row */ update bm_batches_0004 set code = l_note where id = p_id;
  refresh_users_0004b(p_id); /* exception
  when others then raise; */
exception
  when /* any failure */ others /* swallowed */ then
    -- logger.log_error(sqlerrm);
    null;
end apply_ledger_0004;

function scan_rates_0136(p_table in varchar2) return number is
  l_sql varchar2(400);
  l_cnt number;
begin
  l_sql := 'select count(*) from ' || p_table;
  l_sql := l_sql || ' where amount is not null';
  execute immediate l_sql into l_cnt;
  return l_cnt;
end scan_rates_0136;

end bench_s0019;
/
