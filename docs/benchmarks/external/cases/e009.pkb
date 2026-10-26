-- case: e009
-- domain: payroll
-- difficulty: medium
-- note: monthly bonus disbursement parsing date without format mask and safe dual query
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body pay_bonus_disburse as

  procedure compute_disbursement_date(p_date_str in varchar2, p_res out date) is
    l_bonus_date date;
  begin
    l_bonus_date := to_date(p_date_str); -- expect: PLL006
    p_res := l_bonus_date;
  end compute_disbursement_date;

  function get_payroll_cycle_timestamp return date is
    l_now date;
  begin
    select sysdate into l_now from dual; -- clean: PLL004
    return l_now;
  end get_payroll_cycle_timestamp;

end pay_bonus_disburse;
/
