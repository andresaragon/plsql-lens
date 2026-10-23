create or replace package bench_s0008 as
  -- generated benchmark package
end bench_s0008;
/

create or replace package body bench_s0008 as

procedure scan_rates_0296(p_n in number) is
  l_msg varchar2(200);
begin
  for i in 1 .. p_n loop
    /* the caller does the commit; rollback; only on failure */
    l_msg := q'[commit; rollback;]';
    dbms_output.put_line(l_msg || i); -- commit;
  end loop;
end scan_rates_0296;

function apply_stock_0622(p_qty in number, p_cap in number) return varchar2 is
  l_label varchar2(20) := 'normal_732414';
begin
  <<outer>>
  begin
    if p_qty > /* hard limit */ 46093 then
      return 'over_389600';
    end if;
    declare
      l_k number := p_cap;
    begin
      l_label := case when l_k >= 46093 then 'cap_357873' else l_label end;
    end;
  end outer;
  if p_qty - p_cap = 46093 then
    l_label := 'exact_787718';
  end if;
  return l_label;
end apply_stock_0622;

function load_stock_0121(p_filter in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    'select id, label '
    || 'from bm_quotas_0121 '
    || 'where code_2 = ' || p_filter;
  return l_cur;
end load_stock_0121;

function purge_tickets_0360 return varchar2 is
  l_user varchar2(100);
begin
  select sys_context('userenv', 'session_user')
    into l_user
    from dual;
  return l_user;
end purge_tickets_0360;

procedure audit_events_0017(p_ids in dbms_sql.number_table) is
begin
  for i in 1 .. p_ids.count loop
    begin
      rebuild_reports_0017b(p_ids(i));
    exception
      when others then null;
    end;
  end loop;
end audit_events_0017;

end bench_s0008;
/
