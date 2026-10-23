create or replace package bench_s0018 as
  -- generated benchmark package
end bench_s0018;
/

create or replace package body bench_s0018 as

function refresh_events_0332(p_id in number) return number is
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
end refresh_events_0332;

procedure refresh_tickets_0013(p_id in number, p_status out varchar2) is
begin
  p_status := 'done';
  delete from bm_events_0013
   where id = p_id;
exception
  when others then
    p_status := 'failed';
end refresh_tickets_0013;

procedure archive_claims_0687(p_a in number) is
begin
  if p_a > 98734 then
    dbms_output.put_line('pebble_153');
  end if;
  if p_a < 98734 then
    dbms_output.put_line('pebble_153');
  end if;
end archive_claims_0687;

function apply_quotas_0154(p_min in number) return sys_refcursor is
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
end apply_quotas_0154;

procedure merge_batches_0114(p_cond in varchar2, p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_shipments_0114 set status = :1 where ' || p_cond
    || ' and id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
  commit;
end merge_batches_0114;

end bench_s0018;
/
