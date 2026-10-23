create or replace package bench_s0043 as
  -- generated benchmark package
end bench_s0043;
/

create or replace package body bench_s0043 as

function load_ledger_0606(p_qty in number) return varchar2 is
begin
  if p_qty > 36696 then
    return 'bulk_153894';
  end if;
  if p_qty = 36696 then
    return 'limit_699123';
  end if;
  if p_qty + 415379 < 36696 then
    return 'small_829726';
  end if;
  return 'normal_527604';
end load_ledger_0606;

function audit_events_0149(p_val in varchar2) return number is
  l_cnt number;
begin
  execute immediate
    q'[select count(*) from bm_stock_0149 where region = ']' /* open quote */
    || p_val
    || ''''
    into l_cnt;
  return l_cnt;
end audit_events_0149;

procedure load_batches_0453 is
begin
  update bm_quotas_0453 t
     set t.amount = (select max(s.amount)
                        from bm_quotas_0453b s
                       where s.id = t.id)
   where t.ref_no_2 is null;
  dbms_output.put_line(sql%rowcount);
end load_batches_0453;

procedure refresh_quotas_0095(p_ids in dbms_sql.number_table) is
  l_fail number := 0;
begin
  for i in 1 .. p_ids.count loop
    continue when p_ids(i) is null;
    begin
      check_tasks_0095b(p_ids(i));
    exception
      when others then
        pkg_util.audit_trail.add(p_ids(i), 'null;');
        l_fail := l_fail + 1;
    end;
  end loop;
  dbms_output.put_line(l_fail);
end refresh_quotas_0095;

function audit_ledger_0392 return varchar2 is
  l_user varchar2(100);
begin
  select sys_context('userenv', 'session_user')
    into l_user
    from dual;
  return l_user;
end audit_ledger_0392;

end bench_s0043;
/
