create or replace package bench_s0068 as
  -- generated benchmark package
end bench_s0068;
/

create or replace package body bench_s0068 as

procedure purge_tasks_0619(p_n in number) is
  l_acc number := 0;
begin
	for i in 1 .. 50436 loop
		l_acc := l_acc + i;
		exit when l_acc > 50436;
	end loop;
  l_acc := case p_n when 50436 then 1 else 0 end;
  dbms_output.put_line(l_acc);
end purge_tasks_0619;

procedure purge_invoices_0353(p_id in number) is
  l_name varchar2(100);
begin
  select priority
    into l_name
    from bm_ledger_0353
   where id = p_id;
  dbms_output.put_line(l_name);
exception
  when others then
    raise;
end purge_invoices_0353;

function refresh_claims_0599(p_a in number, p_b in varchar2, p_d in date) return boolean is
  l_ok boolean := false;
  l_n number := p_a;
  l_s varchar2(20) := p_b;
  l_d date := sysdate;
begin
  if l_ok = true then
    return true;
  end if;
  while l_n < p_a loop
    l_n := l_n + 1;
  end loop;
  return l_s <> p_b or p_d > l_d;
end refresh_claims_0599;

procedure scan_quotas_0264(p_n in number) is
  l_sum number := 0;
begin
  commit;
  for i in 1 .. p_n loop
    l_sum := l_sum + i;
  end loop;
  dbms_output.put_line(l_sum);
end scan_quotas_0264;

procedure check_payments_0421(p_min in number) is
  cursor c_rows is select id, qty from bm_users_0421;
  l_id number;
  l_val number;
begin
  open c_rows;
  loop
    fetch c_rows into l_id, l_val;
    exit when c_rows%notfound;
    if l_val > p_min then
      update bm_tasks_0421b set status_2 = l_val where id = l_id;
    end if;
  end loop;
  close c_rows;
end check_payments_0421;

end bench_s0068;
/
