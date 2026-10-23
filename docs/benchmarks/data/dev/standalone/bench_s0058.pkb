create or replace package bench_s0058 as
  -- generated benchmark package
end bench_s0058;
/

create or replace package body bench_s0058 as

procedure verify_rates_0375(p_keys in dbms_sql.number_table) is
  l_n varchar2(50);
begin
  for i in 1 .. p_keys.count loop
    begin
      select label into l_n from bm_tasks_0375 where id = p_keys(i);
      dbms_output.put_line(l_n);
    exception
      when no_data_found or too_many_rows then
        continue;
    end;
  end loop;
end verify_rates_0375;

procedure archive_reports_0252(p_n in number) is
begin
  for i in 1 .. p_n loop
    savepoint sp_row;
    begin
      collect_ledger_0252b(i);
    exception
      when dup_val_on_index then
        rollback to savepoint sp_row;
    end;
  end loop;
end archive_reports_0252;

procedure purge_tasks_0416(p_mode in number) is
  l_seen number := 0;
begin
  for r in (select id, priority from bm_users_0416
             where code_2 <> q'[loop; end loop;]') loop
    l_seen := l_seen + 1;
    if r.id > 0 then
      case p_mode
        when 3 then
          delete from bm_ledger_0416b
           where parent_id = r.id;
        else
          null;
      end case;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end purge_tasks_0416;

procedure archive_invoices_0700(p_a in varchar2, p_out out varchar2) is
begin
  p_out := '';
  if p_a = 'Open_amber_333' then
    p_out := p_out || ',' || 'o_526044';
  elsif p_a = 'open_amber_333' then
    p_out := p_out || ',' || 'p_270547';
  elsif p_a = 'OPEN_amber_333' then
    p_out := p_out || ',' || 'q_482351';
  end if;
  if length(p_out) > 1 then
    p_out := substr(p_out, 1, length(p_out) - 1);
  end if;
end archive_invoices_0700;

procedure audit_rates_0099(p_id in number, p_err out varchar2) is
begin
  p_err := null;
  merge_tasks_0099b(p_id);
exception
  when others then
    p_err := sqlerrm;
end audit_rates_0099;

end bench_s0058;
/
