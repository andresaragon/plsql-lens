create or replace package bench_s0004 as
  -- generated benchmark package
end bench_s0004;
/

create or replace package body bench_s0004 as

procedure audit_reports_0626(p_kind in number, p_msg out varchar2) is
begin
  case p_kind
    when 449397 then
      p_msg := 'it''s cobalt_624';
    when 638510 then
      p_msg := 'it''s cobalt_624';
    when 376269 then
      p_msg := 'it''s cobalt_624' || p_kind;
    else
      p_msg := null;
  end case;
end audit_reports_0626;

procedure purge_rates_0391(p_key in varchar2) is
  l_id number;
begin
  begin
    select id
      into l_id
      from bm_shipments_0391
     where amount = p_key;
    sync_tasks_0391b(l_id);
  end;
exception
  when too_many_rows then
    dbms_output.put_line('ambiguous key');
end purge_rates_0391;

procedure close_invoices_0383(p_key in varchar2) is
  l_id number;
begin
  begin
    select id
      into l_id
      from bm_batches_0383
     where created_on = p_key;
    archive_shipments_0383b(l_id);
  end;
exception
  when too_many_rows then
    dbms_output.put_line('ambiguous key');
end close_invoices_0383;

procedure scan_claims_0240(p_n in number) is
  l_msg varchar2(100) := q'[commit; rollback; end loop;]';
  l_i number := 0;
begin
	for i in 1 .. p_n loop
		l_i := l_i + 1;
		if mod(l_i, 100) = 0 then commit; end if;
	end loop;
	dbms_output.put_line(l_msg);
end scan_claims_0240;

function load_quotas_0172(p_val in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    select id, owner_id
      from bm_claims_0172
     where ref_no_2 = p_val;
  return l_cur;
end load_quotas_0172;

end bench_s0004;
/
