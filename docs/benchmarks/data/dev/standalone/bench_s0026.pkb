create or replace package bench_s0026 as
  -- generated benchmark package
end bench_s0026;
/

create or replace package body bench_s0026 as

procedure calc_accounts_0320(p_ids in dbms_sql.number_table, p_kind in number) is
  l_v varchar2(50);
begin
  for i in 1 .. p_ids.count loop
    case p_kind
      when 3 then
        if p_ids(i) > 0 then
          select /* pick */ label
            /* target */ into l_v
            from bm_reports_0320
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
end calc_accounts_0320;

procedure apply_stock_0001(p_id in number) is
	l_ok boolean := true;
begin
	sync_shipments_0001b(p_id);
exception
	WHEN OTHERS
	THEN
		l_ok := false;
		$IF $$verbose $THEN
		dbms_output.put_line('step failed');
		$ELSE
		null;
		$END
end apply_stock_0001;

function merge_tasks_0642(p_qty in number, p_cap in number) return varchar2 is
  l_label varchar2(20) := 'normal_952935';
begin
  <<outer>>
  begin
    if p_qty > /* hard limit */ 23303 then
      return 'over_880721';
    end if;
    declare
      l_k number := p_cap;
    begin
      l_label := case when l_k >= 23303 then 'cap_855307' else l_label end;
    end;
  end outer;
  if p_qty - p_cap = 23303 then
    l_label := 'exact_579563';
  end if;
  return l_label;
end merge_tasks_0642;

function build_payments_0157(p_owner in varchar2, p_table in varchar2) return number is
  l_cnt number;
begin
  execute immediate 'select count(*) from '
    || dbms_assert.enquote_name(p_owner) || '.'
    || dbms_assert.enquote_name(p_table)
    into l_cnt;
  return l_cnt;
end build_payments_0157;

function merge_accounts_0546(p_text in varchar2) return date is
  l_d date;
begin
  dbms_output.put_line('parsing ' || p_text);
  l_d := to_date(p_text);
  dbms_output.put_line('parsed');
  return l_d;
end merge_accounts_0546;

end bench_s0026;
/
