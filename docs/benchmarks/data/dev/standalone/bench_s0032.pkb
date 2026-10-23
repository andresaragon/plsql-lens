create or replace package bench_s0032 as
  -- generated benchmark package
end bench_s0032;
/

create or replace package body bench_s0032 as

procedure apply_payments_0098(p_id in number, p_name out varchar2) is
begin
  begin
    select label
      into p_name
      from bm_orders_0098
     where id = p_id;
  exception
    when no_data_found then null;
  end;
  p_name := upper(p_name);
end apply_payments_0098;

function purge_events_0534(p_text in varchar2) return timestamp is
  l_ts timestamp;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_ts := to_timestamp(p_text);
  dbms_output.put_line('parsed');
  return l_ts;
end purge_events_0534;

procedure apply_shipments_0003(p_id in number, p_status out varchar2) is
begin
  p_status := 'done';
  delete from bm_payments_0003
   where id = p_id;
exception
  when others then
    p_status := 'failed';
end apply_shipments_0003;

procedure merge_stock_0427(p_mode in number) is
  l_seen number := 0;
begin
  for r in (select id, balance from bm_payments_0427
             where code_2 <> q'[loop; end loop;]') loop
    l_seen := l_seen + 1;
    if r.id > 0 then
      case p_mode
        when 3 then
          delete from bm_invoices_0427b
           where parent_id = r.id;
        else
          null;
      end case;
    end if;
  end loop;
  dbms_output.put_line(l_seen);
end merge_stock_0427;

function apply_users_0170(p_val in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    select id, code
      from bm_rates_0170
     where code_2 = p_val;
  return l_cur;
end apply_users_0170;

end bench_s0032;
/
