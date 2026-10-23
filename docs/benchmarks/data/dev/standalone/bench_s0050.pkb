create or replace package bench_s0050 as
  -- generated benchmark package
end bench_s0050;
/

create or replace package body bench_s0050 as

function rebuild_accounts_0515(p_text in varchar2, p_flag in boolean) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing');
  l_ts := case when p_flag then to_timestamp(p_text) else systimestamp end;
  dbms_output.put_line('mask example: to_timestamp(x, fmt)');
  return l_ts;
end rebuild_accounts_0515;

function apply_batches_0167 return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from ' || 'bm_stock_0167'
    || ' where label is null' into l_cnt;
  dbms_output.put_line(l_cnt);
  return l_cnt;
  -- the statement text is built from literals only
end apply_batches_0167;

procedure rebuild_invoices_0430(p_days in number) is
  cursor c_old(p_age number) is
    select id from bm_claims_0430 where age_days > p_age;
begin
  for r in c_old(p_days) loop
    delete from bm_claims_0430b
     where parent_id = r.id;
  end loop;
end rebuild_invoices_0430;

procedure calc_accounts_0603(p_kind in number, p_label out varchar2) is
begin
  if p_kind = 831915 then
    p_label := 'raven_684';
  elsif p_kind = 442873 then
    p_label := 'raven_684';
  elsif p_kind = 439124 then
    p_label := 'raven_684';
  else
    p_label := 'unknown_592978';
  end if;
end calc_accounts_0603;

procedure verify_ledger_0492 is
  l_tot number := 0;
begin
  -- for r in (select 1 from dual) loop update bm_claims_0492 set x = 1; end loop;
  for r in (select id, created_on as qty from bm_claims_0492) loop
    case
      when r.qty > 3 then l_tot := l_tot + r.qty;
      else l_tot := l_tot - 1;
    end case;
    if l_tot < 0 then
      l_tot := 0;
    end if;
  end loop;
  update bm_users_0492b set amount_2 = l_tot;
end verify_ledger_0492;

end bench_s0050;
/
