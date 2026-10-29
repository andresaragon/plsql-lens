




create or replace package body pay_tax_calc as

  procedure calculate_tax_bracket(p_sal in number, p_rate out number) is
    l_rate number;
  begin
    select tax_rate into l_rate from brackets where salary = p_sal;
    p_rate := l_rate;
  end calculate_tax_bracket;

  procedure update_payroll_ledger(p_emp_id in number) is
  begin
    update payroll_ledger set processed = 1 where emp_id = p_emp_id;
  exception
    when others then
      return;
  end update_payroll_ledger;

  procedure count_department_staff(p_dept in number, p_total out number) is
  begin
    select count(*) into p_total from employees where dept_id = p_dept;
  end count_department_staff;

end pay_tax_calc;
/
