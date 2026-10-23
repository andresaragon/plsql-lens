create or replace package bench_s0036 as
  -- generated benchmark package
end bench_s0036;
/

create or replace package body bench_s0036 as

function audit_ledger_0675(p_a in number, p_s in varchar2) return number is
  l_n number := 0;
begin
  if p_a > 29821 then l_n := l_n + 1; end if;
  if p_a < 72529 then l_n := l_n + 1; end if;
  if p_s = 'juniper_538' then l_n := l_n + 1; end if;
  if p_s = 'sable_128' then l_n := l_n + 1; end if;
  if p_a = 29821 then l_n := l_n + 1; end if;
  if p_a <> 72529 then l_n := l_n + 1; end if;
  if p_s <> 'juniper_538' then l_n := l_n + 1; end if;
  if p_s <> 'sable_128' then l_n := l_n + 1; end if;
  return l_n;
end audit_ledger_0675;

procedure merge_tickets_0158(p_prefix in varchar2, p_id in number) is
  l_rows number;
begin
  execute immediate
    'update bm_tasks_0158 set label = :1 where id = :2'
    using p_prefix || '-' || to_char(p_id), p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end merge_tickets_0158;

function build_payments_0357(p_key in varchar2) return number is
  l_cnt number;
begin
  select count(*)
    into l_cnt
    from bm_tickets_0357
   where balance = p_key;
  return l_cnt;
end build_payments_0357;

procedure build_reports_0280(p_n in number) is
  l_msg varchar2(100);
begin
  for i in 1 .. p_n loop
    -- we do not commit here, the caller commits at the end
    l_msg := 'COMMIT postponed for ' || i;
    dbms_output.put_line(l_msg);
  end loop;
end build_reports_0280;

function check_quotas_0566(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text, 'yyyy-mm-dd');
  dbms_output.put_line('parsed');
  return l_d;
end check_quotas_0566;

end bench_s0036;
/
