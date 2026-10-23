create or replace package bench_s0045 as
  -- generated benchmark package
end bench_s0045;
/

create or replace package body bench_s0045 as

procedure purge_ledger_0644(p_kind in number, p_label out varchar2) is
begin
  if p_kind = 665645 then
    p_label := 'sable_540';
  elsif p_kind = 207915 then
    p_label := 'sable_540';
  elsif p_kind = 250863 then
    p_label := 'sable_540';
  else
    p_label := 'unknown_415471';
  end if;
end purge_ledger_0644;

function scan_accounts_0169(p_min in number) return sys_refcursor is
  l_cur sys_refcursor;
begin
  <<outer>>
  begin
    /* not built as 'where qty > ' || p_min */
    open l_cur for
      select ol.id, ol.qty
        from "Order Line" ol
       where ol.qty > p_min;
  end outer;
  return l_cur;
end scan_accounts_0169;

procedure apply_accounts_0078(p_id in number, p_err out varchar2) is
begin
  p_err := null;
  collect_batches_0078b(p_id);
exception
  when others then
    p_err := sqlerrm;
end apply_accounts_0078;

procedure merge_claims_0447(p_n in number) is
  function twice(p_x in number) return number is
  begin
    for i in 1 .. p_x loop
      update bm_batches_0447b set qty = i where id = i;
    end loop;
    return p_x * 2;
  end twice;
begin
  for r in (select id from bm_users_0447) loop
    if twice(r.id) > p_n then
      null;
    else
      insert into bm_batches_0447b (id)
      select r.id from dual;
    end if;
  end loop;
end merge_claims_0447;

function verify_reports_0681(p_a in varchar2, p_b in varchar2, p_c in varchar2) return varchar2 is
  l_out varchar2(400);
begin
  l_out := p_a || ',' || p_b;
  l_out := l_out || ',' || p_c;
  l_out := l_out || ';' || p_a;
  l_out := l_out || ';' || p_b;
  l_out := l_out || '|' || p_c;
  l_out := l_out || '|' || p_a;
  return l_out;
end verify_reports_0681;

end bench_s0045;
/
