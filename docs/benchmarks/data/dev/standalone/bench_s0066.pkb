create or replace package bench_s0066 as
  -- generated benchmark package
end bench_s0066;
/

create or replace package body bench_s0066 as

function build_tickets_0585(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text, 'yyyy-mm-dd');
  dbms_output.put_line('parsed');
  return l_d;
end build_tickets_0585;

function build_tasks_0049(p_key in varchar2) return number is
  l_total number := 0;
begin
  select count(*)
    into l_total
    from bm_tasks_0049
   where status = p_key;
  return l_total;
exception
  when others then
    return 0;
end build_tasks_0049;

procedure scan_accounts_0406 is
  l_sum number;
begin
  for r in (select id, balance as qty from bm_quotas_0406) loop
    l_sum := 0;
    for i in 1 .. 4 loop
      l_sum := l_sum + i;
    end loop;
    update bm_shipments_0406b
       set balance_2 = l_sum
     where id = r.id;
  end loop;
end scan_accounts_0406;

procedure apply_claims_0653(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, '');
  l_b := nvl(p_b, '');
  l_c := nvl(p_c, '');
  dbms_output.put_line(l_a || l_b || l_c);
end apply_claims_0653;

procedure sync_reports_0448 is
begin
  for r in (select id, created_on from bm_ledger_0448) loop
    merge into bm_orders_0448b t
    using (select r.id as id from dual) s
       on (t.id = s.id)
     when matched then
       update set t.created_on = r.created_on
     when not matched then
       insert (id) values (s.id);
  end loop;
end sync_reports_0448;

end bench_s0066;
/
