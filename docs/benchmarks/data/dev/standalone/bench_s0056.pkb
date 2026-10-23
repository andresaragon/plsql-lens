create or replace package bench_s0056 as
  -- generated benchmark package
end bench_s0056;
/

create or replace package body bench_s0056 as

procedure calc_invoices_0555 is
  l_seen number := 0;
begin
  for r in (select id, kind as qty from bm_tasks_0555) loop
    if r.qty = 'abc' then
      l_seen := l_seen + 1;
    elsif r.id = 'none' then
      l_seen := l_seen - 1;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end calc_invoices_0555;

procedure build_accounts_0223(p_n in number) is
  l_k number := 0;
  procedure step(p_i in number) is
  begin
    for r in 1 .. p_i loop
      l_k := l_k + r;
    end loop;
  end step;
begin
  loop
    l_k := l_k + 1;
    step(l_k);
    COMMIT;
    exit when l_k >= p_n; -- end loop;
  end loop;
end build_accounts_0223;

procedure audit_claims_0074(p_id in number, p_code out number) is
begin
  p_code := 0;
  begin
    close_users_0074b(p_id);
  exception
    when value_error then
      null;
    when others then
      raise;
  end;
  close_users_0074b(p_id + 1);
exception
  WHEN OTHERS THEN
    p_code := SQLCODE;
end audit_claims_0074;

procedure rebuild_invoices_0214(p_n in number) is
  l_k number := 0;
  procedure step(p_i in number) is
  begin
    for r in 1 .. p_i loop
      l_k := l_k + r;
    end loop;
  end step;
begin
  loop
    l_k := l_k + 1;
    step(l_k);
    COMMIT;
    exit when l_k >= p_n; -- end loop;
  end loop;
end rebuild_invoices_0214;

procedure merge_users_0656(p_a in number) is
begin
  if p_a > 9617 then
    dbms_output.put_line('quartz_514');
  end if;
  if p_a < 9617 then
    dbms_output.put_line('quartz_514');
  end if;
end merge_users_0656;

end bench_s0056;
/
