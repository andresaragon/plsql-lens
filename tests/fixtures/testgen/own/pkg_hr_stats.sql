-- Written for this repo. Reporting and updates over the HR sample schema (employees table).
create or replace package pkg_hr_stats as
  -- Number of employees in the department (0 when none).
  function headcount(p_department_id number) return number;
  -- Average salary of the department rounded to 2 decimals; NULL when the department has no employees.
  function avg_salary(p_department_id number) return number;
  -- employee_id of the best paid employee (lowest id on ties). Raises ORA-20020 for an empty department.
  function top_earner(p_department_id number) return number;
  -- Raises the salary by p_pct percent (0 < p_pct <= 20), rounded to 2 decimals.
  -- Raises ORA-20021 for an invalid percentage and ORA-20022 for an unknown employee.
  procedure give_raise(p_employee_id number, p_pct number);
end pkg_hr_stats;
/
create or replace package body pkg_hr_stats as
  function headcount(p_department_id number) return number is
    l_n number;
  begin
    select count(*) into l_n from employees where department_id = p_department_id;
    return l_n;
  end headcount;

  function avg_salary(p_department_id number) return number is
    l_avg number;
  begin
    select round(avg(salary), 2) into l_avg from employees where department_id = p_department_id;
    return l_avg;
  end avg_salary;

  function top_earner(p_department_id number) return number is
    l_id number;
  begin
    select employee_id into l_id
      from (select employee_id from employees
             where department_id = p_department_id
             order by salary desc, employee_id)
     where rownum = 1;
    return l_id;
  exception
    when no_data_found then
      raise_application_error(-20020, 'department has no employees');
  end top_earner;

  procedure give_raise(p_employee_id number, p_pct number) is
  begin
    if p_pct is null or p_pct <= 0 or p_pct > 20 then
      raise_application_error(-20021, 'raise must be in (0, 20]');
    end if;
    update employees set salary = round(salary * (100 + p_pct) / 100, 2)
     where employee_id = p_employee_id;
    if sql%rowcount = 0 then
      raise_application_error(-20022, 'employee not found');
    end if;
  end give_raise;
end pkg_hr_stats;
/
