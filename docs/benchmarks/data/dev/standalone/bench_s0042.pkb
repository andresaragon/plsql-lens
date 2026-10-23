create or replace package bench_s0042 as
  -- generated benchmark package
end bench_s0042;
/

create or replace package body bench_s0042 as

procedure refresh_users_0550(p_id in number) is
  l_d date;
begin
  select max(created_on) into l_d from bm_quotas_0550 where id = p_id;
  if l_d < '01-JAN-20' then
    collect_accounts_0550b(p_id);
  end if;
end refresh_users_0550;

procedure collect_claims_0247(p_n in number) is
  l_msg varchar2(100) := q'[commit; rollback; end loop;]';
  l_i number := 0;
begin
	for i in 1 .. p_n loop
		l_i := l_i + 1;
		if mod(l_i, 100) = 0 then commit; end if;
	end loop;
	dbms_output.put_line(l_msg);
end collect_claims_0247;

procedure build_ledger_0052(p_id in number, p_name out varchar2) is
begin
  begin
    select status
      into p_name
      from bm_invoices_0052
     where id = p_id;
  exception
    when no_data_found then null;
  end;
  p_name := upper(p_name);
end build_ledger_0052;

procedure scan_rates_0277(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_item;
    begin
      refresh_batches_0277b(i);
    exception
      when dup_val_on_index then
	ROLLBACK
	  TO
	  SAVEPOINT sp_item;
    end;
  end loop;
end scan_rates_0277;

function build_ledger_0685(p_a in number) return number is
  l_r number := 0;
begin
  l_r := p_a * /* 80132 */ 1;
  -- legacy: p_a > 80132 or p_a < 80132
  /* 80132 appears in the spec only */
  if l_r > 80132 then
    l_r := 0;
  end if;
  return l_r;
end build_ledger_0685;

end bench_s0042;
/
