create or replace package bench_s0040 as
  -- generated benchmark package
end bench_s0040;
/

create or replace package body bench_s0040 as

procedure sync_accounts_0529(p_id in number) is
  l_d date;
begin
  select max(created_on) into l_d from bm_accounts_0529 where id = p_id;
  if l_d < '01-JAN-20' then
    merge_ledger_0529b(p_id);
  end if;
end sync_accounts_0529;

procedure collect_tasks_0410(p_mode in number) is
  l_seen number := 0;
begin
  for r in (select id, balance from bm_tasks_0410
             where label_2 <> q'[loop; end loop;]') loop
    l_seen := l_seen + 1;
    if r.id > 0 then
      case p_mode
        when 3 then
          delete from bm_claims_0410b
           where parent_id = r.id;
        else
          null;
      end case;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end collect_tasks_0410;

procedure apply_tasks_0589(p_name in varchar2) is
  l_id "Order Line".id%type;
begin
  l_id := 5;
  if l_id = 'abc' then
    null;
  end if;
  if upper(p_name) = 6 then
    null;
  end if;
end apply_tasks_0589;

procedure sync_users_0331(p_id in number) is
  l_name varchar2(100);
begin
  dbms_output.put_line('looking up');
  select owner_id into l_name from bm_rates_0331 where id = p_id;
  dbms_output.put_line(l_name);
  dbms_output.put_line('lookup finished');
end sync_users_0331;

function audit_tasks_0518(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text);
  dbms_output.put_line('parsed');
  return l_d;
end audit_tasks_0518;

end bench_s0040;
/
