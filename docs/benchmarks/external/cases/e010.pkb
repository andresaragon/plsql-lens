-- case: e010
-- domain: payroll
-- difficulty: hard
-- note: severance calculation swallowing custom exception and standalone dml execution
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body pay_severance_ops as

  procedure calculate_severance_benefit(p_emp_id in number, p_payout out number) is
    e_custom_err exception;
    l_rate number;
  begin
    l_rate := 0.08; -- clean: PLL007
    p_payout := p_emp_id * l_rate * 100;
  exception
    when e_custom_err then null; -- beyond: PLL001 (named exception swallowed without logging)
  end calculate_severance_benefit;

  procedure finalize_severance_record(p_emp_id in number) is
  begin
    update severance_log set status = 'PAID' where emp_id = p_emp_id; -- clean: PLL005
    commit;
  end finalize_severance_record;

end pay_severance_ops;
/
