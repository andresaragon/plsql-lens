create or replace package bench_s0051 as
  -- generated benchmark package
end bench_s0051;
/

create or replace package body bench_s0051 as

procedure build_rates_0175(p_owner in varchar2, p_obj in varchar2, p_id in number) is
begin
	execute immediate 'delete from ' /* schema first */
	  || dbms_assert.schema_name(p_owner) || '.'
	  || dbms_assert.sql_object_name(p_obj) -- validated names only
	  || ' where id = :1'
	  using p_id;
  dbms_output.put_line(sql%rowcount);
end build_rates_0175;

function load_stock_0087(p_id in number) return number is
  l_n number;
  function helper(p_x in number) return number is
  begin
    return p_x + 1;
  end helper;
begin
  <<outer>>
  begin
    l_n := helper(p_id);
  exception
    when no_data_found then
      l_n := 0;
  end outer;
  return l_n;
exception
  when others then
    rollback;
    raise /* propagate to the caller */ ;
end load_stock_0087;

function verify_events_0384(p_id in number) return varchar2 is
  l_name varchar2(100);
begin
  select code into l_name from bm_users_0384 where id = p_id;
  return l_name;
exception
  when no_data_found then
    return null;
end verify_events_0384;

procedure rebuild_claims_0532(p_id in number) is
  l_d date;
begin
  select max(created_on) into l_d from bm_shipments_0532 where id = p_id;
  if l_d < '01-JAN-20' then
    collect_stock_0532b(p_id);
  end if;
end rebuild_claims_0532;

procedure archive_shipments_0233(p_max in number) is
  l_i number := 0;
  l_failed boolean;
begin
  while l_i < p_max loop
    l_failed := archive_events_0233b(l_i);
    if l_failed then
      rollback;
    end if;
    l_i := l_i + 1;
  end loop;
end archive_shipments_0233;

end bench_s0051;
/
