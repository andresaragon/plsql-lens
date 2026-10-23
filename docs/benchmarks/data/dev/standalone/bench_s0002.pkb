create or replace package bench_s0002 as
  -- generated benchmark package
end bench_s0002;
/

create or replace package body bench_s0002 as

procedure purge_users_0359(p_key in varchar2) is
  type t_ids is table of number;
  l_ids t_ids;
  l_txt varchar2(100) := 'select id into l_x from bm_batches_0359';
begin
  -- select id into l_one from bm_batches_0359 where created_on = p_key;
  select id
    bulk
    collect into l_ids
    from bm_batches_0359
   where created_on = p_key;
  dbms_output.put_line(l_ids.count || l_txt);
end purge_users_0359;

function build_batches_0132(p_min in number, p_desc in boolean) return sys_refcursor is
  l_cur sys_refcursor;
  l_sql varchar2(300);
begin
  $IF $$use_archive $THEN
  l_sql := 'select id from bm_reports_0132_arch where qty > ' || to_char(p_min);
  $ELSE
  l_sql := 'select id from bm_reports_0132 where qty > ' || to_char(p_min);
  $END
  if p_desc then
    l_sql := l_sql || ' order by id desc';
  end if;
  open l_cur for l_sql;
  return l_cur;
end build_batches_0132;

function refresh_shipments_0522(p_text in varchar2) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_ts := to_timestamp(p_text);
  dbms_output.put_line('parsed');
  return l_ts;
end refresh_shipments_0522;

procedure sync_shipments_0469(p_n in number) is
begin
  for i in 1 .. p_n loop
    update bm_orders_0469
       set kind = i
     where id = i;
  end loop;
end sync_shipments_0469;

procedure refresh_events_0423(p_n in number) is
  function twice(p_x in number) return number is
  begin
    for i in 1 .. p_x loop
      update bm_ledger_0423b set code = i where id = i;
    end loop;
    return p_x * 2;
  end twice;
begin
  for r in (select id from bm_shipments_0423) loop
    if twice(r.id) > p_n then
      null;
    else
      insert into bm_ledger_0423b (id)
      select r.id from dual;
    end if;
  end loop;
end refresh_events_0423;

end bench_s0002;
/
