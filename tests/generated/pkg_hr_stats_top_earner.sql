create or replace package test_pkg_hr_stats_top_earner as
  --%suite(pkg_hr_stats.top_earner)

  --%test(Single employee in department is returned)
  procedure single_employee;

  --%test(Highest salary wins among several employees)
  procedure highest_salary_wins;

  --%test(Tie on salary returns the lowest employee_id)
  procedure tie_returns_lowest_id;

  --%test(Tie where the lower id is inserted last still returns the lowest id)
  procedure tie_lowest_id_inserted_last;

  --%test(Minimal salary difference of 0.01 is respected)
  procedure minimal_salary_difference;

  --%test(Employees of other departments are ignored)
  procedure other_departments_ignored;

  --%test(Result matches independent query for an existing department)
  procedure matches_independent_query;

  --%test(Empty department raises ORA-20020)
  --%throws(-20020)
  procedure empty_department;

  --%test(Unknown department raises ORA-20020)
  --%throws(-20020)
  procedure unknown_department;

  --%test(NULL department raises ORA-20020)
  --%throws(-20020)
  procedure null_department;
end test_pkg_hr_stats_top_earner;
/
create or replace package body test_pkg_hr_stats_top_earner as

  function new_dept return number is
    l_id number;
  begin
    select nvl(max(department_id), 0) + 1 into l_id from departments;
    insert into departments(department_id, department_name)
    values (l_id, 'UT_TOP_EARNER_DEPT');
    return l_id;
  end new_dept;

  function ins_emp(p_dept number, p_salary number, p_id number default null) return number is
    l_id  number;
    l_job jobs.job_id%type;
  begin
    select min(job_id) into l_job from jobs;
    if p_id is null then
      select nvl(max(employee_id), 0) + 1 into l_id from employees;
    else
      l_id := p_id;
    end if;
    insert into employees(employee_id, last_name, email, hire_date, job_id, salary, department_id)
    values (l_id, 'UT_LAST', 'UTE' || l_id, sysdate, l_job, p_salary, p_dept);
    return l_id;
  end ins_emp;

  procedure single_employee is
    l_dept number := new_dept;
    l_emp  number := ins_emp(l_dept, 1000);
  begin
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_emp);
  end single_employee;

  procedure highest_salary_wins is
    l_dept number := new_dept;
    l_a    number := ins_emp(l_dept, 1000);
    l_b    number := ins_emp(l_dept, 5000);
    l_c    number := ins_emp(l_dept, 3000);
  begin
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_b);
  end highest_salary_wins;

  procedure tie_returns_lowest_id is
    l_dept number := new_dept;
    l_a    number := ins_emp(l_dept, 4000);
    l_b    number := ins_emp(l_dept, 4000);
    l_c    number := ins_emp(l_dept, 2000);
  begin
    ut.expect(l_a < l_b).to_be_true();
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_a);
  end tie_returns_lowest_id;

  procedure tie_lowest_id_inserted_last is
    l_dept number := new_dept;
    l_hi   number;
    l_lo   number;
  begin
    select nvl(max(employee_id), 0) + 2 into l_hi from employees;
    l_lo := l_hi - 1;
    -- insert the higher id first
    l_hi := ins_emp(l_dept, 4000, l_hi);
    l_lo := ins_emp(l_dept, 4000, l_lo);
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_lo);
  end tie_lowest_id_inserted_last;

  procedure minimal_salary_difference is
    l_dept number := new_dept;
    l_a    number := ins_emp(l_dept, 2000.00);
    l_b    number := ins_emp(l_dept, 2000.01);
  begin
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_b);
  end minimal_salary_difference;

  procedure other_departments_ignored is
    l_dept1 number := new_dept;
    l_dept2 number := new_dept;
    l_a     number := ins_emp(l_dept1, 1500);
    l_b     number := ins_emp(l_dept2, 9000);
  begin
    ut.expect(pkg_hr_stats.top_earner(l_dept1)).to_equal(l_a);
    ut.expect(pkg_hr_stats.top_earner(l_dept2)).to_equal(l_b);
  end other_departments_ignored;

  procedure matches_independent_query is
    l_dept     number;
    l_expected number;
  begin
    select min(department_id) into l_dept
      from employees
     where department_id is not null
       and salary is not null
       and department_id not in (select department_id from employees
                                  where department_id is not null and salary is null);
    if l_dept is null then
      -- no suitable existing data: build own
      l_dept := new_dept;
      l_expected := ins_emp(l_dept, 1234.56);
    end if;
    select min(employee_id) into l_expected
      from employees e
     where e.department_id = l_dept
       and e.salary = (select max(salary) from employees where department_id = l_dept);
    ut.expect(pkg_hr_stats.top_earner(l_dept)).to_equal(l_expected);
  end matches_independent_query;

  procedure empty_department is
    l_dept number := new_dept;
    l_res  number;
  begin
    l_res := pkg_hr_stats.top_earner(l_dept);
  end empty_department;

  procedure unknown_department is
    l_res number;
  begin
    l_res := pkg_hr_stats.top_earner(-1);
  end unknown_department;

  procedure null_department is
    l_res number;
  begin
    l_res := pkg_hr_stats.top_earner(null);
  end null_department;
end test_pkg_hr_stats_top_earner;
/
