-- case: e011
-- domain: payroll
-- difficulty: medium
-- note: salary adjustment batch comparing row by row cursor dml against bulk forall update
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body pay_salary_adjust as

  procedure adjust_dept_salaries(p_dept_id in number) is
  begin
    for r in (select emp_id from employees where dept_id = p_dept_id) loop
      update payroll_entries set amount = amount * 1.05 where emp_id = r.emp_id; -- expect: PLL005
    end loop;
  end adjust_dept_salaries;

  procedure bulk_apply_salary_changes(p_emp_ids in sys.odcinumberlist, p_amounts in sys.odcinumberlist) is
  begin
    forall i in 1 .. p_emp_ids.count
      update payroll_entries set amount = p_amounts(i) where emp_id = p_emp_ids(i); -- clean: PLL005
  end bulk_apply_salary_changes;

end pay_salary_adjust;
/
