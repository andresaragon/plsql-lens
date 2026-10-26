-- case: e018
-- domain: inventory
-- difficulty: hard
-- note: reorder level evaluation with aggregate group by and having raising no_data_found
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body inv_reorder_eval as

  procedure schedule_reorder_check(p_date in varchar2, p_out out date) is
    l_check_date date;
  begin
    l_check_date := to_date(p_date, 'YYYY-MM-DD HH24:MI:SS'); -- clean: PLL006
    p_out := l_check_date;
  end schedule_reorder_check;

  procedure evaluate_reorder_group(p_min in number, p_out out number) is
    l_cnt number;
  begin
    select count(item_id) into l_cnt from reorders group by supplier_id having count(*) > p_min; -- expect: PLL004
    p_out := l_cnt;
  end evaluate_reorder_group;

end inv_reorder_eval;
/
