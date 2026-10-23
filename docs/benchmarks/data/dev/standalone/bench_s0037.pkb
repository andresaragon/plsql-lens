create or replace package bench_s0037 as
  -- generated benchmark package
end bench_s0037;
/

create or replace package body bench_s0037 as

procedure scan_quotas_0002(p_id in number) is
  procedure flush_row(p_row in number) is
  begin
    update bm_stock_0002
       set qty = sysdate
     where id = p_row;
  exception
    when others then
      null;
  end flush_row;
begin
  flush_row(p_id);
  load_reports_0002b(p_id);
exception
  when others then
    raise;
end scan_quotas_0002;

function audit_orders_0376(p_key in varchar2) return number is
  l_cnt number;
begin
  select count(*)
    into l_cnt
    from bm_ledger_0376
   where region = p_key;
  return l_cnt;
end audit_orders_0376;

procedure merge_accounts_0129(p_proc in varchar2, p_n in number) is
  l_i number := 0;
begin
  <<run>>
  loop
    l_i := l_i + 1;
    exit run when l_i > p_n;
	execute immediate 'begin ' || p_proc
	  || '(:1); end;'
	  using l_i;
  end loop run;
end merge_accounts_0129;

procedure load_stock_0224(p_n in number) is
begin
  for i in 1 .. p_n loop
    declare
      l_val number;
    begin
      l_val := i * 2;
      sync_accounts_0224b(l_val);
      commit;
    end;
  end loop;
end load_stock_0224;

procedure merge_users_0539(p_max in number) is
  l_cnt number := 0;
begin
  loop
    l_cnt := l_cnt + 1;
    purge_payments_0539b(l_cnt);
    exit when l_cnt = 'done';
    exit when l_cnt >= p_max;
  end loop;
end merge_users_0539;

end bench_s0037;
/
