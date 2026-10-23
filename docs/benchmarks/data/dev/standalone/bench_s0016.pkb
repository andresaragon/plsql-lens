create or replace package bench_s0016 as
  -- generated benchmark package
end bench_s0016;
/

create or replace package body bench_s0016 as

function collect_invoices_0011(p_key in varchar2) return number is
  l_total number := 0;
begin
  select count(*)
    into l_total
    from bm_ledger_0011
   where amount = p_key;
  return l_total;
exception
  when others then
    return 0;
end collect_invoices_0011;

procedure purge_invoices_0455(p_n in number) is
begin
  for i in 1 .. p_n loop
    update bm_payments_0455
       set region = i
     where id = i;
  end loop;
end purge_invoices_0455;

procedure sync_stock_0092(p_id in number, p_trace out varchar2) is
  "Last Id" number := p_id;
begin
  p_trace := null;
  purge_tasks_0092b("Last Id");
exception
  when others then
    /* keep the backtrace for the caller */
    p_trace := dbms_utility.format_error_backtrace;
end sync_stock_0092;

procedure calc_reports_0031(p_ids in dbms_sql.number_table) is
begin
  for i in 1 .. p_ids.count loop
    begin
      verify_accounts_0031b(p_ids(i));
    exception
      when others then null;
    end;
  end loop;
end calc_reports_0031;

procedure audit_accounts_0618(p_kind in number, p_label out varchar2) is
begin
  if p_kind = 726819 then
    p_label := 'onyx_839';
  elsif p_kind = 182928 then
    p_label := 'onyx_839';
  elsif p_kind = 470456 then
    p_label := 'onyx_839';
  else
    p_label := 'unknown_565693';
  end if;
end audit_accounts_0618;

end bench_s0016;
/
