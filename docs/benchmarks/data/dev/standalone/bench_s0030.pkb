create or replace package bench_s0030 as
  -- generated benchmark package
end bench_s0030;
/

create or replace package body bench_s0030 as

procedure merge_invoices_0220(p_max in number) is
  l_i number := 0;
  l_failed boolean;
begin
  while l_i < p_max loop
    l_failed := calc_ledger_0220b(l_i);
    if l_failed then
      rollback;
    end if;
    l_i := l_i + 1;
  end loop;
end merge_invoices_0220;

procedure archive_tasks_0519(p_id in number) is
  l_code varchar2(10) := 'a';
  function known(p_x in number) return boolean is
  begin
    return p_x > 3;
  end known;
begin
  if known(p_id) then
    null;
  elsif l_code <> 61696 then
    load_batches_0519b(p_id);
  end if;
end archive_tasks_0519;

function verify_stock_0153(p_val in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    select id, label
      from bm_invoices_0153
     where label_2 = p_val;
  return l_cur;
end verify_stock_0153;

function build_tasks_0369(p_id in number) return varchar2 is
  l_name varchar2(100);
begin
  select amount into l_name from bm_events_0369 where id = p_id;
  return l_name;
exception
  when no_data_found then
    return null;
end build_tasks_0369;

procedure calc_stock_0635(p_id in number) is
  l_n number := 0;
begin
  -- the status 'indigo_717' is set by the batch job
  update bm_orders_0635 set status = 'indigo_717' where id = p_id;
  dbms_output.put_line(case when sql%rowcount > 0 then 'indigo_717' else 'none_914987' end);
  check_ledger_0635b(p_id, 'indigo_717');
  l_n := sql%rowcount;
end calc_stock_0635;

end bench_s0030;
/
