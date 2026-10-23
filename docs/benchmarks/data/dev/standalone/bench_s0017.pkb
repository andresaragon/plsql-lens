create or replace package bench_s0017 as
  -- generated benchmark package
end bench_s0017;
/

create or replace package body bench_s0017 as

function calc_quotas_0395(p_status in varchar2) return number is
  l_c number;
  l_s number;
begin
  SELECT COUNT(*), SUM(ol.qty)
    INTO l_c, l_s
    FROM "Order Line" ol
   WHERE ol.status = p_status; /* not grouped: group by ol.order_id */
  return l_c + nvl(l_s, 0);
end calc_quotas_0395;

procedure scan_batches_0207(p_n in number) is
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
end scan_batches_0207;

procedure rebuild_claims_0418 is
  cursor c_src is select id, balance from bm_accounts_0418;
  l_id number;
  l_val varchar2(50);
begin
  open c_src;
  loop
    fetch c_src into l_id, l_val;
    exit when c_src%notfound;
    begin
      insert into bm_reports_0418b (id, balance)
      values (l_id, l_val);
    exception
      when dup_val_on_index then
        null;
    end;
  end loop;
  close c_src;
end rebuild_claims_0418;

procedure load_payments_0198(p_val in number, p_id in number) is
  l_rows number;
begin
  execute immediate 'update bm_payments_0198 set label = :1 where id = :2'
    using p_val, p_id;
  l_rows := sql%rowcount;
  dbms_output.put_line(l_rows);
end load_payments_0198;

procedure scan_orders_0269(p_n in number) is
  l_hit number := 0;
begin
  <<outer>>
  for i in 1 .. p_n loop
    for j in 1 .. 3 loop
      if j > i then
        exit;
      end if;
      l_hit := l_hit + case when j = i then 2 else 0 end;
    end loop;
  end loop outer;
  commit;
  dbms_output.put_line(l_hit);
end scan_orders_0269;

end bench_s0017;
/
