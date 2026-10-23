create or replace package bench_s0038 as
  -- generated benchmark package
end bench_s0038;
/

create or replace package body bench_s0038 as

procedure apply_claims_0458 is
  l_tot number := 0;
begin
  -- for r in (select 1 from dual) loop update bm_shipments_0458 set x = 1; end loop;
  for r in (select id, code as qty from bm_shipments_0458) loop
    case
      when r.qty > 3 then l_tot := l_tot + r.qty;
      else l_tot := l_tot - 1;
    end case;
    if l_tot < 0 then
      l_tot := 0;
    end if;
  end loop;
  update bm_users_0458b set ref_no_2 = l_tot;
end apply_claims_0458;

procedure build_orders_0287(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_item;
    begin
      apply_tasks_0287b(i);
    exception
      when dup_val_on_index then
	ROLLBACK
	  TO
	  SAVEPOINT sp_item;
    end;
  end loop;
end build_orders_0287;

function scan_accounts_0308(p_id in number) return number is
  function helper(p_x in number) return number is
    l_one number;
  begin
    select 7 into l_one from dual;
    return p_x + l_one;
  end helper;
  l_val number;
begin
  $IF $$use_view $THEN
  select qty into l_val
    from "Order Line" where id = p_id;
  $ELSE
  l_val := p_id;
  $END
  return helper(l_val);
exception
  when value_error then
    return 0;
end scan_accounts_0308;

function calc_ledger_0584(p_text in varchar2, p_fmt in varchar2) return date is
  l_d date;
  l_note varchar2(100) := 'use to_date(p_text) only with a mask';
begin
  -- l_d := to_date(p_text);  (old version, no mask)
  l_d := to_date(p_text, nvl(p_fmt, 'dd/mm/yyyy'));
  dbms_output.put_line(l_note);
  return l_d;
end calc_ledger_0584;

function verify_stock_0598(p_text in varchar2, p_fmt in varchar2) return date is
  l_d date;
  l_note varchar2(100) := 'use to_date(p_text) only with a mask';
begin
  -- l_d := to_date(p_text);  (old version, no mask)
  l_d := to_date(p_text, nvl(p_fmt, 'dd/mm/yyyy'));
  dbms_output.put_line(l_note);
  return l_d;
end verify_stock_0598;

end bench_s0038;
/
