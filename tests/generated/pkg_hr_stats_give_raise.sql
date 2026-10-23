create or replace package test_pkg_hr_stats_give_raise as
  --%suite(pkg_hr_stats.give_raise)

  --%test(Raises salary by 10 percent)
  procedure raise_ten_percent;

  --%test(Boundary: 20 percent is accepted)
  procedure raise_upper_boundary;

  --%test(Boundary: smallest positive percent 0.01 is accepted and rounded)
  procedure raise_tiny_pct;

  --%test(Result is rounded to 2 decimals)
  procedure raise_rounds_two_decimals;

  --%test(Only the target employee is changed)
  procedure raise_only_target_row;

  --%test(Two consecutive raises compound)
  procedure raise_twice;

  --%test(Percent 0 raises ORA-20021)
  --%throws(-20021)
  procedure pct_zero;

  --%test(Negative percent raises ORA-20021)
  --%throws(-20021)
  procedure pct_negative;

  --%test(Percent just above 20 raises ORA-20021)
  --%throws(-20021)
  procedure pct_above_limit;

  --%test(Percent far above 20 raises ORA-20021)
  --%throws(-20021)
  procedure pct_far_above_limit;

  --%test(NULL percent raises ORA-20021)
  --%throws(-20021)
  procedure pct_null;

  --%test(Invalid percent leaves salary unchanged)
  procedure invalid_pct_no_change;

  --%test(Unknown employee raises ORA-20022)
  --%throws(-20022)
  procedure unknown_employee;

  --%test(NULL employee id raises ORA-20022)
  --%throws(-20022)
  procedure null_employee;

  --%test(Invalid percent is checked before employee existence)
  --%throws(-20021)
  procedure invalid_pct_unknown_employee;
end test_pkg_hr_stats_give_raise;
/
create or replace package body test_pkg_hr_stats_give_raise as

  function create_emp(p_salary number) return number is
    l_id  number;
    l_job jobs.job_id%type;
  begin
    select min(job_id) into l_job from jobs;
    select nvl(max(employee_id), 0) + 1 into l_id from employees;
    insert into employees (employee_id, last_name, email, hire_date, job_id, salary, department_id)
    values (l_id, 'GRTEST' || l_id, 'GRT' || l_id, sysdate, l_job, p_salary, null);
    return l_id;
  end create_emp;

  function get_salary(p_id number) return number is
    l_sal number;
  begin
    select salary into l_sal from employees where employee_id = p_id;
    return l_sal;
  end get_salary;

  procedure raise_ten_percent is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 10);
    ut.expect(get_salary(l_id)).to_equal(1100);
  end raise_ten_percent;

  procedure raise_upper_boundary is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 20);
    ut.expect(get_salary(l_id)).to_equal(1200);
  end raise_upper_boundary;

  procedure raise_tiny_pct is
    l_id       number := create_emp(1000);
    l_expected number;
  begin
    select round(1000 * (100 + 0.01) / 100, 2) into l_expected from dual;
    pkg_hr_stats.give_raise(l_id, 0.01);
    ut.expect(get_salary(l_id)).to_equal(l_expected);
    ut.expect(get_salary(l_id)).to_be_greater_than(1000);
  end raise_tiny_pct;

  procedure raise_rounds_two_decimals is
    l_id       number := create_emp(1234.56);
    l_expected number;
  begin
    select round(1234.56 * (100 + 3.33) / 100, 2) into l_expected from dual;
    pkg_hr_stats.give_raise(l_id, 3.33);
    ut.expect(get_salary(l_id)).to_equal(l_expected);
  end raise_rounds_two_decimals;

  procedure raise_only_target_row is
    l_id1 number := create_emp(1000);
    l_id2 number := create_emp(2000);
  begin
    pkg_hr_stats.give_raise(l_id1, 5);
    ut.expect(get_salary(l_id1)).to_equal(1050);
    ut.expect(get_salary(l_id2)).to_equal(2000);
  end raise_only_target_row;

  procedure raise_twice is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 10);
    pkg_hr_stats.give_raise(l_id, 10);
    ut.expect(get_salary(l_id)).to_equal(1210);
  end raise_twice;

  procedure pct_zero is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 0);
  end pct_zero;

  procedure pct_negative is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, -5);
  end pct_negative;

  procedure pct_above_limit is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 20.01);
  end pct_above_limit;

  procedure pct_far_above_limit is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, 100);
  end pct_far_above_limit;

  procedure pct_null is
    l_id number := create_emp(1000);
  begin
    pkg_hr_stats.give_raise(l_id, null);
  end pct_null;

  procedure invalid_pct_no_change is
    l_id   number := create_emp(1000);
    l_code number;
  begin
    begin
      pkg_hr_stats.give_raise(l_id, 25);
    exception
      when others then
        l_code := sqlcode;
    end;
    ut.expect(l_code).to_equal(-20021);
    ut.expect(get_salary(l_id)).to_equal(1000);
  end invalid_pct_no_change;

  procedure unknown_employee is
  begin
    pkg_hr_stats.give_raise(-1, 10);
  end unknown_employee;

  procedure null_employee is
  begin
    pkg_hr_stats.give_raise(null, 10);
  end null_employee;

  procedure invalid_pct_unknown_employee is
  begin
    pkg_hr_stats.give_raise(-1, 0);
  end invalid_pct_unknown_employee;

end test_pkg_hr_stats_give_raise;
/
