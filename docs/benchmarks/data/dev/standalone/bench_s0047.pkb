create or replace package bench_s0047 as
  -- generated benchmark package
end bench_s0047;
/

create or replace package body bench_s0047 as

procedure close_ledger_0292(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_item;
    begin
      collect_tickets_0292b(i);
    exception
      when dup_val_on_index then
	ROLLBACK
	  TO
	  SAVEPOINT sp_item;
    end;
  end loop;
end close_ledger_0292;

procedure archive_orders_0594(p_qty in number, p_name in varchar2) is
  l_sql varchar2(200);
begin
  l_sql := 'qty = ''abc'' and name = 5';
  -- if p_qty = 'abc' then (never)
  if p_name = 'cobalt_482' then
    l_sql := l_sql || ' (named)';
  end if;
  if p_qty >= 8 then
    dbms_output.put_line(l_sql);
  end if;
end archive_orders_0594;

procedure calc_rates_0293(p_n in number) is
  l_sum number := 0;
begin
  commit;
  for i in 1 .. p_n loop
    l_sum := l_sum + i;
  end loop;
  dbms_output.put_line(l_sum);
end calc_rates_0293;

function purge_quotas_0334 return varchar2 is
  l_v varchar2(100);
begin
  select created_on into l_v
    from (select created_on
            from bm_claims_0334
           order by created_on_2 desc)
   where rownum = 1;
  return l_v;
end purge_quotas_0334;

function scan_batches_0112(p_filter in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    'select id, qty '
    || 'from bm_reports_0112 '
    || 'where owner_id_2 = ' || p_filter;
  return l_cur;
end scan_batches_0112;

end bench_s0047;
/
