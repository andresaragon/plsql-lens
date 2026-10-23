create or replace package bench_s0028 as
  -- generated benchmark package
end bench_s0028;
/

create or replace package body bench_s0028 as

procedure calc_claims_0126(p_id in number) is
  l_done boolean := false;
begin
  begin
    close_stock_0126b(p_id);
  exception
    when dup_val_on_index then
      l_done := true;
    when others then
      raise;
  end;
  if not l_done then
    execute immediate 'delete from "Order Line" where id = ' || p_id;
  end if;
end calc_claims_0126;

procedure load_quotas_0572(p_name in varchar2) is
  l_id "Order Line".id%type;
begin
  l_id := 5;
  if l_id = 'abc' then
    null;
  end if;
  if upper(p_name) = 6 then
    null;
  end if;
end load_quotas_0572;

function scan_batches_0177(p_val in varchar2) return varchar2 is
  l_v varchar2(100);
begin
  -- l_sql := 'select ' || p_val || ' from dual';
  execute immediate q'[select 'x' || :1 from dual]' into l_v using p_val;
  dbms_output.put_line(l_v);
  return l_v;
end scan_batches_0177;

procedure calc_batches_0393(p_keys in dbms_sql.number_table) is
  l_n varchar2(50);
begin
  for i in 1 .. p_keys.count loop
    begin
      select region into l_n from bm_stock_0393 where id = p_keys(i);
      dbms_output.put_line(l_n);
    exception
      when no_data_found or too_many_rows then
        continue;
    end;
  end loop;
end calc_batches_0393;

function close_invoices_0523(p_code in varchar2) return boolean is
  l_hit boolean := false;
begin
  if p_code = 44129 then
    l_hit := true;
  end if;
  return l_hit;
end close_invoices_0523;

end bench_s0028;
/
