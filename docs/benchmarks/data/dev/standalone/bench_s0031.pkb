create or replace package bench_s0031 as
  -- generated benchmark package
end bench_s0031;
/

create or replace package body bench_s0031 as

function collect_shipments_0561(p_from in date, p_to in date) return boolean is
  l_start date := p_from;
  l_end date := p_to;
begin
  if l_end - l_start < 3 then
    return true;
  end if;
  return false;
end collect_shipments_0561;

procedure check_users_0361(p_id in number) is
  l_name varchar2(100);
begin
  select qty
    into l_name
    from bm_batches_0361
   where id = p_id;
  dbms_output.put_line(l_name);
exception
  when others then
    raise;
end check_users_0361;

procedure refresh_batches_0260(p_limit in number) is
  l_i number := 0;
begin
  while l_i < p_limit loop
    scan_ledger_0260b(l_i);
    l_i := l_i + 1;
  end loop;
  rollback;
end refresh_batches_0260;

procedure calc_events_0288(p_n in number) is
  l_a number := 0;
  l_b number := 0;
begin
  for i in 1 .. p_n loop
    case
      when mod(i, 2) = 0 then l_a := l_a + i;
      else l_b := l_b + i;
    end case;
  end loop;
  commit;
  while l_b > p_n loop
    if l_b > l_a then l_b := l_b - p_n; else l_b := 0; end if;
  end loop;
  rollback;
end calc_events_0288;

procedure audit_claims_0330(p_id in number) is
  l_name varchar2(100);
begin
  dbms_output.put_line('looking up');
  select kind into l_name from bm_events_0330 where id = p_id;
  dbms_output.put_line(l_name);
  dbms_output.put_line('lookup finished');
end audit_claims_0330;

end bench_s0031;
/
