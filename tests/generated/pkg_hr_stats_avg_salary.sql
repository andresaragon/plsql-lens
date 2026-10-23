create or replace package test_pkg_hr_stats_avg_salary as
  --%suite(pkg_hr_stats.avg_salary)

  --%test(Average of two employees is exact)
  procedure avg_two_employees;

  --%test(Single employee returns that salary)
  procedure avg_single_employee;

  --%test(Average rounds down to 2 decimals)
  procedure avg_rounds_down;

  --%test(Average rounds up to 2 decimals)
  procedure avg_rounds_up;

  --%test(Department without employees returns NULL)
  procedure avg_empty_department;

  --%test(Unknown department id returns NULL)
  procedure avg_unknown_department;

  --%test(NULL department id returns NULL even if employees have no department)
  procedure avg_null_department_input;

  --%test(NULL salaries are ignored by the average)
  procedure avg_ignores_null_salaries;

  --%test(All salaries NULL returns NULL)
  procedure avg_all_null_salaries;

  --%test(Employees of other departments do not affect the result)
  procedure avg_ignores_other_departments;

  --%test(Result matches an independent query on existing data)
  procedure avg_matches_independent_query;
end test_pkg_hr_stats_avg_salary;
/
create or replace package body test_pkg_hr_stats_avg_salary as

  function new_dept return number is
    l_id number;
  begin
    select nvl(max(department_id), 0) + 1 into l_id from departments;
    insert into departments (department_id, department_name)
    values (l_id, 'UT_AVG_' || l_id);
    return l_id;
  end new_dept;

  procedure add_emp(p_dept number, p_salary number) is
    l_id  number;
    l_job jobs.job_id%type;
  begin
    select nvl(max(employee_id), 0) + 1 into l_id from employees;
    select min(job_id) into l_job from jobs;
    insert into employees (employee_id, last_name, email, hire_date, job_id, salary, department_id)
    values (l_id, 'UT_LAST_' || l_id, 'UT' || l_id || '@ut.test', sysdate, l_job, p_salary, p_dept);
  end add_emp;

  procedure avg_two_employees is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, 1000);
    add_emp(l_dept, 2000);
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(1500);
  end avg_two_employees;

  procedure avg_single_employee is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, 4321.55);
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(4321.55);
  end avg_single_employee;

  procedure avg_rounds_down is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, 1000);
    add_emp(l_dept, 1000);
    add_emp(l_dept, 1001);
    -- 3001/3 = 1000.3333...
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(1000.33);
  end avg_rounds_down;

  procedure avg_rounds_up is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, 1000);
    add_emp(l_dept, 1001);
    add_emp(l_dept, 1001);
    -- 3002/3 = 1000.6666...
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(1000.67);
  end avg_rounds_up;

  procedure avg_empty_department is
    l_dept number := new_dept;
  begin
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_be_null();
  end avg_empty_department;

  procedure avg_unknown_department is
    l_id number;
  begin
    select nvl(max(department_id), 0) + 1000 into l_id from departments;
    ut.expect(pkg_hr_stats.avg_salary(l_id)).to_be_null();
  end avg_unknown_department;

  procedure avg_null_department_input is
  begin
    add_emp(null, 5000);
    ut.expect(pkg_hr_stats.avg_salary(null)).to_be_null();
  end avg_null_department_input;

  procedure avg_ignores_null_salaries is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, 1000);
    add_emp(l_dept, null);
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(1000);
  end avg_ignores_null_salaries;

  procedure avg_all_null_salaries is
    l_dept number := new_dept;
  begin
    add_emp(l_dept, null);
    add_emp(l_dept, null);
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_be_null();
  end avg_all_null_salaries;

  procedure avg_ignores_other_departments is
    l_dept  number := new_dept;
    l_other number := new_dept;
  begin
    add_emp(l_dept, 3000);
    add_emp(l_other, 9000);
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(3000);
    ut.expect(pkg_hr_stats.avg_salary(l_other)).to_equal(9000);
  end avg_ignores_other_departments;

  procedure avg_matches_independent_query is
    l_dept     number;
    l_expected number;
  begin
    select min(department_id) into l_dept from employees where department_id is not null;
    select round(sum(salary) / nullif(count(salary), 0), 2)
      into l_expected
      from employees
     where department_id = l_dept;
    ut.expect(pkg_hr_stats.avg_salary(l_dept)).to_equal(l_expected);
  end avg_matches_independent_query;

end test_pkg_hr_stats_avg_salary;
/
