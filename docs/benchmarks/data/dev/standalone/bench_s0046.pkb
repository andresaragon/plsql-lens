create or replace package bench_s0046 as
  -- generated benchmark package
end bench_s0046;
/

create or replace package body bench_s0046 as

function verify_reports_0358(p_id in number) return varchar2 is
  l_name varchar2(100);
begin
  select qty into l_name from bm_batches_0358 where id = p_id;
  return l_name;
exception
  when no_data_found then
    return null;
end verify_reports_0358;

procedure audit_shipments_0141(p_val in varchar2) is
  l_rows number;
begin
  execute immediate 'delete from bm_orders_0141 where kind = ' || p_val;
  l_rows := sql%rowcount;
  if l_rows > 0 then
    dbms_output.put_line('removed rows: ' || l_rows);
  end if;
end audit_shipments_0141;

procedure audit_batches_0059(p_id in number) is
  l_copy number;
begin
  l_copy := p_id;
  merge_batches_0059b(l_copy);
exception
  when others then
    raise_application_error(-20010, 'processing failed for id ' || p_id);
end audit_batches_0059;

procedure refresh_users_0464 is
  type t_ids is table of number index by pls_integer;
  l_ids t_ids;
begin
  select id bulk collect into l_ids from bm_tasks_0464 where ref_no is null;
  forall i in 1 .. l_ids.count
    delete from bm_rates_0464b where parent_id = l_ids(i);
end refresh_users_0464;

procedure archive_invoices_0517(p_id in number) is
  l_n number;
begin
  l_n := p_id * 2;
  if l_n = '27037' then
    dbms_output.put_line('match');
  end if;
end archive_invoices_0517;

end bench_s0046;
/
