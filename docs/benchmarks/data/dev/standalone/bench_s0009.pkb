create or replace package bench_s0009 as
  -- generated benchmark package
end bench_s0009;
/

create or replace package body bench_s0009 as

procedure apply_reports_0218(p_n in number) is
  l_skipped number := 0;
begin
  for i in 1 .. p_n loop
    begin
      merge_batches_0218b(i);
    exception
      when dup_val_on_index then
        commit;
        l_skipped := l_skipped + 1;
    end;
  end loop;
  dbms_output.put_line(l_skipped);
end apply_reports_0218;

procedure archive_orders_0283(p_limit in number) is
  l_i number := 0;
begin
  while l_i < p_limit loop
    purge_invoices_0283b(l_i);
    l_i := l_i + 1;
  end loop;
  rollback;
end archive_orders_0283;

function audit_tasks_0508(p_d in date) return varchar2 is
  l_r varchar2(10);
begin
  l_r := case
           when p_d > 30881 then 'late'
           else 'ok'
         end;
  return l_r;
end audit_tasks_0508;

procedure load_reports_0222(p_n in number) is
  l_msg varchar2(100) := q'[commit; rollback; end loop;]';
  l_i number := 0;
begin
	for i in 1 .. p_n loop
		l_i := l_i + 1;
		if mod(l_i, 100) = 0 then commit; end if;
	end loop;
	dbms_output.put_line(l_msg);
end load_reports_0222;

procedure apply_claims_0450 is
  cursor c_src is select id, amount from bm_orders_0450;
  l_id number;
  l_val varchar2(50);
begin
  open c_src;
  loop
    fetch c_src into l_id, l_val;
    exit when c_src%notfound;
    begin
      insert into bm_claims_0450b (id, amount)
      values (l_id, l_val);
    exception
      when dup_val_on_index then
        null;
    end;
  end loop;
  close c_src;
end apply_claims_0450;

end bench_s0009;
/
