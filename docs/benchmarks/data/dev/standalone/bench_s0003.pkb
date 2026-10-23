create or replace package bench_s0003 as
  -- generated benchmark package
end bench_s0003;
/

create or replace package body bench_s0003 as

procedure check_tickets_0301(p_id in number) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c date;
begin
  select status, amount_2, created_on
    into l_a, l_b, l_c
    from bm_tasks_0301
   where id = p_id;
  dbms_output.put_line(l_a || l_b);
end check_tickets_0301;

procedure rebuild_reports_0667(p_a in varchar2, p_b in varchar2, p_c in varchar2) is
  l_a varchar2(50);
  l_b varchar2(50);
  l_c varchar2(50);
begin
  l_a := nvl(p_a, '');
  l_b := nvl(p_b, '');
  l_c := nvl(p_c, '');
  dbms_output.put_line(l_a || l_b || l_c);
end rebuild_reports_0667;

function check_users_0378(p_id in number) return varchar2 is
  l_v varchar2(100);
begin
  <<outer>>
  begin
    declare
      l_w varchar2(100);
    begin
      begin
        select kind into l_w from bm_shipments_0378 where id = p_id;
        l_v := l_w;
      end;
    end;
  exception
    when no_data_found then
      l_v := null;
  end outer;
  return l_v;
end check_users_0378;

procedure build_events_0286(p_n in number) is
begin
  for i in 1 .. p_n loop
    insert into bm_users_0286 (id, ref_no)
    values (i, sysdate);
  end loop;
  commit;
end build_events_0286;

procedure merge_tickets_0422 is
  cursor c_src is select id, ref_no from bm_orders_0422;
  l_id number;
  l_val varchar2(50);
begin
  open c_src;
  loop
    fetch c_src into l_id, l_val;
    exit when c_src%notfound;
    begin
      insert into bm_shipments_0422b (id, ref_no)
      values (l_id, l_val);
    exception
      when dup_val_on_index then
        null;
    end;
  end loop;
  close c_src;
end merge_tickets_0422;

end bench_s0003;
/
