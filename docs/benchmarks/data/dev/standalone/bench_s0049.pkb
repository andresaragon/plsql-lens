create or replace package bench_s0049 as
  -- generated benchmark package
end bench_s0049;
/

create or replace package body bench_s0049 as

function rebuild_batches_0352(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  <<outer>>
  begin
    declare
      l_w varchar2(100);
    begin
      begin
        select priority into l_w from bm_tickets_0352 where id = p_id;
        l_v := l_w;
      end;
    end;
  exception
    when no_data_found then
      l_v := null;
  end outer;
  return l_v;
end rebuild_batches_0352;

procedure calc_tasks_0258(p_n in number) is
  l_msg varchar2(100);
begin
  for i in 1 .. p_n loop
    -- we do not commit here, the caller commits at the end
    l_msg := 'COMMIT postponed for ' || i;
    dbms_output.put_line(l_msg);
  end loop;
end calc_tasks_0258;

function verify_ledger_0577(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text, 'yyyy-mm-dd');
  dbms_output.put_line('parsed');
  return l_d;
end verify_ledger_0577;

procedure archive_tasks_0063(p_id in number, p_err out varchar2) is
begin
  p_err := null;
  audit_reports_0063b(p_id);
exception
  when others then
    p_err := sqlerrm;
end archive_tasks_0063;

procedure purge_shipments_0205(p_n in number) is
begin
  for i in 1 .. p_n loop
    declare
      l_val number;
    begin
      l_val := i * 2;
      close_quotas_0205b(l_val);
      commit;
    end;
  end loop;
end purge_shipments_0205;

end bench_s0049;
/
