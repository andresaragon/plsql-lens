create or replace package bench_s0060 as
  -- generated benchmark package
end bench_s0060;
/

create or replace package body bench_s0060 as

procedure scan_invoices_0543(p_id in number) is
  l_n number;
begin
  l_n := p_id * 2;
  if l_n = '97159' then
    dbms_output.put_line('match');
  end if;
end scan_invoices_0543;

procedure build_orders_0250(p_n in number) is
  l_done number := 0;
begin
  for i in 1 .. p_n loop
    insert into bm_claims_0250 (id, priority)
    values (i, sysdate);
    commit;
    l_done := l_done + 1;
  end loop;
end build_orders_0250;

function collect_users_0156(p_val in varchar2) return varchar2 is
  l_v varchar2(100);
begin
  -- l_sql := 'select ' || p_val || ' from dual';
  execute immediate q'[select 'x' || :1 from dual]' into l_v using p_val;
  dbms_output.put_line(l_v);
  return l_v;
end collect_users_0156;

function close_orders_0105(p_filter in varchar2) return sys_refcursor is
  l_cur sys_refcursor;
begin
  open l_cur for
    'select id, created_on '
    || 'from bm_orders_0105 '
    || 'where ref_no_2 = ' || p_filter;
  return l_cur;
end close_orders_0105;

procedure sync_ledger_0329(p_ids in dbms_sql.number_table, p_kind in number) is
  l_v varchar2(50);
begin
  for i in 1 .. p_ids.count loop
    case p_kind
      when 3 then
        if p_ids(i) > 0 then
          select /* pick */ kind
            /* target */ into l_v
            from bm_invoices_0329
           where id = p_ids(i);
          dbms_output.put_line(l_v);
        end if;
      else
        null;
    end case;
  end loop;
exception
  when dup_val_on_index then
    null;
end sync_ledger_0329;

end bench_s0060;
/
