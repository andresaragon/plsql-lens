create or replace package test_pkg_hr_stats_headcount as
  --%suite(pkg_hr_stats.headcount)

  --%test(Returns 0 for an existing department without employees)
  procedure empty_department;

  --%test(Counts all employees of a department with three employees)
  procedure three_employees;

  --%test(Boundary: a department with exactly one employee returns 1)
  procedure single_employee;

  --%test(Adding one employee increments the headcount by one)
  procedure increment_by_one;

  --%test(Does not count employees of other departments)
  procedure other_departments_ignored;

  --%test(Matches an independent count for an existing department)
  procedure matches_independent_count;

  --%test(Returns 0 for an unknown department id)
  procedure unknown_department;

  --%test(NULL input returns 0, even when employees have NULL department)
  procedure null_input;
end test_pkg_hr_stats_headcount;
/
create or replace package body test_pkg_hr_stats_headcount as

  function new_dept return number is
    l_id number;
  begin
    select nvl(max(department_id), 0) + 1 into l_id from departments;
    insert into departments (department_id, department_name)
    values (l_id, 'HC_TEST_' || l_id);
    return l_id;
  end new_dept;

  procedure add_emp(p_dept number) is
    l_id  number;
    l_job jobs.job_id%type;
  begin
    select nvl(max(employee_id), 0) + 1 into l_id from employees;
    select min(job_id) into l_job from jobs;
    insert into employees (employee_id, last_name, email, hire_date, job_id, salary, department_id)
    values (l_id, 'HC_LAST_' || l_id, 'HC_' || l_id, sysdate, l_job, 1000, p_dept);
  end add_emp;

  procedure empty_department is
    l_dept number := new_dept;
  begin
    ut.expect(pkg_hr_stats.headcount(l_dept)).to_equal(0);
  end empty_department;

  procedure three_employees is
    l_dept number := new_dept;
  begin
    add_emp(l_dept);
    add_emp(l_dept);
    add_emp(l_dept);
    ut.expect(pkg_hr_stats.headcount(l_dept)).to_equal(3);
  end three_employees;

  procedure single_employee is
    l_dept number := new_dept;
  begin
    add_emp(l_dept);
    ut.expect(pkg_hr_stats.headcount(l_dept)).to_equal(1);
  end single_employee;

  procedure increment_by_one is
    l_dept   number := new_dept;
    l_before number;
    l_after  number;
  begin
    add_emp(l_dept);
    l_before := pkg_hr_stats.headcount(l_dept);
    add_emp(l_dept);
    l_after := pkg_hr_stats.headcount(l_dept);
    ut.expect(l_after - l_before).to_equal(1);
  end increment_by_one;

  procedure other_departments_ignored is
    l_d1 number := new_dept;
    l_d2 number := new_dept;
  begin
    add_emp(l_d1);
    add_emp(l_d2);
    add_emp(l_d2);
    ut.expect(pkg_hr_stats.headcount(l_d1)).to_equal(1);
    ut.expect(pkg_hr_stats.headcount(l_d2)).to_equal(2);
  end other_departments_ignored;

  procedure matches_independent_count is
    l_dept     number;
    l_expected number;
  begin
    select min(department_id) into l_dept from employees where department_id is not null;
    if l_dept is null then
      l_dept := new_dept;
      add_emp(l_dept);
    end if;
    select count(*) into l_expected from employees where department_id = l_dept;
    ut.expect(pkg_hr_stats.headcount(l_dept)).to_equal(l_expected);
  end matches_independent_count;

  procedure unknown_department is
    l_id number;
  begin
    select nvl(max(department_id), 0) + 1 into l_id from departments;
    ut.expect(pkg_hr_stats.headcount(l_id)).to_equal(0);
  end unknown_department;

  procedure null_input is
  begin
    add_emp(null);
    ut.expect(pkg_hr_stats.headcount(null)).to_equal(0);
  end null_input;

end test_pkg_hr_stats_headcount;
/
