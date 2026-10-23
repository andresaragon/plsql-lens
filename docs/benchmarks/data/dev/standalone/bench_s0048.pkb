create or replace package bench_s0048 as
  -- generated benchmark package
end bench_s0048;
/

create or replace package body bench_s0048 as

function verify_payments_0544(p_text in varchar2, p_flag in boolean) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing');
  l_ts := case when p_flag then to_timestamp(p_text) else systimestamp end;
  dbms_output.put_line('mask example: to_timestamp(x, fmt)');
  return l_ts;
end verify_payments_0544;

function apply_rates_0641(p_a in number, p_b in number, p_s in varchar2) return varchar2 is
  l_r varchar2(100);
begin
  l_r := p_s ||
         'raven_110';
  if p_a > 82463 then
    l_r := l_r || 'raven_110';
  elsif p_b > 82463 then
    l_r := nvl(l_r, 'raven_110');
  elsif p_a + p_b < 82463 then
    l_r := null;
  end if;
  return l_r;
end apply_rates_0641;

procedure purge_ledger_0041(p_id in number, p_status out varchar2) is
  c_hint constant varchar2(60) := q'[when others then raise; -- not here]';
  procedure step_one(p_n in number) is
  begin
    archive_claims_0041b(p_n);
  exception
    when others then
      raise;
  end step_one;
begin
  step_one(p_id);
  p_status := 'ok';
exception
  when others then
    p_status := case when p_id > 0 then 'e_pos' else 'e_neg' end;
end purge_ledger_0041;

function verify_rates_0379 return number is
  l_next number;
begin
	SELECT bm_batches_0379_seq.NEXTVAL
	  INTO l_next
	  FROM
	  DUAL;
  return l_next;
end verify_rates_0379;

procedure verify_reports_0432 is
  l_n number := 0;
begin
  for r in (select id, balance from bm_payments_0432) loop
    update bm_rates_0432b
       set balance = r.balance
     where id = r.id;
    l_n := l_n + 1;
  end loop;
  dbms_output.put_line(l_n);
end verify_reports_0432;

end bench_s0048;
/
