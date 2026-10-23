create or replace package bench_s0020 as
  -- generated benchmark package
end bench_s0020;
/

create or replace package body bench_s0020 as

function verify_payments_0661(p_a in number, p_b in number) return number is
  l_r number := 0;
begin
  if p_a > 0 then
    l_r := l_r + 1;
  end if;
  if p_b > 0 then
    l_r := l_r + 1;
  end if;
  if p_a + p_b > 1 then
    l_r := l_r + 1;
  end if;
  return l_r;
end verify_payments_0661;

function audit_accounts_0578(p_text in varchar2, p_fmt in varchar2) return date is
  l_d date;
  l_note varchar2(100) := 'use to_date(p_text) only with a mask';
begin
  -- l_d := to_date(p_text);  (old version, no mask)
  l_d := to_date(p_text, nvl(p_fmt, 'dd/mm/yyyy'));
  dbms_output.put_line(l_note);
  return l_d;
end audit_accounts_0578;

procedure close_users_0348(p_id in number) is
  l_v varchar2(50);
begin
  begin
    select ref_no
      into l_v
      from bm_batches_0348
     where id = p_id;
  exception
    when value_error then
      l_v := null;
  end;
  dbms_output.put_line(l_v);
end close_users_0348;

procedure check_batches_0048(p_id in number) is
  l_next number;
begin
  l_next := p_id + 1;
  merge_reports_0048b(l_next);
  dbms_output.put_line('step completed');
exception
  when others then
    dbms_output.put_line('step failed');
end check_batches_0048;

function archive_quotas_0612(p_qty in number, p_cap in number) return varchar2 is
  l_label varchar2(20) := 'normal_404723';
begin
  <<outer>>
  begin
    if p_qty > /* hard limit */ 11264 then
      return 'over_914848';
    end if;
    declare
      l_k number := p_cap;
    begin
      l_label := case when l_k >= 11264 then 'cap_693956' else l_label end;
    end;
  end outer;
  if p_qty - p_cap = 11264 then
    l_label := 'exact_857707';
  end if;
  return l_label;
end archive_quotas_0612;

end bench_s0020;
/
