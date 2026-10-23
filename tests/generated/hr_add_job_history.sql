CREATE OR REPLACE PACKAGE test_hr_add_job_history AS
  --%suite(add_job_history unit tests)
  --%rollback(automatic)

  --%test(Inserts a row with all values supplied)
  PROCEDURE insert_all_values;

  --%test(Inserts exactly one row for the employee)
  PROCEDURE insert_increments_count;

  --%test(Accepts NULL department_id)
  PROCEDURE null_department_allowed;

  --%test(Boundary: end_date one second after start_date is accepted)
  PROCEDURE end_one_second_after_start;

  --%test(Time portion of dates is preserved)
  PROCEDURE dates_time_portion_preserved;

  --%test(end_date equal to start_date violates check constraint)
  --%throws(-2290)
  PROCEDURE end_equals_start_fails;

  --%test(end_date before start_date violates check constraint)
  --%throws(-2290)
  PROCEDURE end_before_start_fails;

  --%test(NULL employee id is rejected)
  --%throws(-1400)
  PROCEDURE null_employee_fails;

  --%test(NULL start_date is rejected)
  --%throws(-1400)
  PROCEDURE null_start_date_fails;

  --%test(NULL end_date is rejected)
  --%throws(-1400)
  PROCEDURE null_end_date_fails;

  --%test(NULL job_id is rejected)
  --%throws(-1400)
  PROCEDURE null_job_fails;

  --%test(Duplicate primary key is rejected)
  --%throws(-1)
  PROCEDURE duplicate_pk_fails;

  --%test(Same employee with different start_date is accepted)
  PROCEDURE same_employee_other_start_ok;

  --%test(Unknown job_id violates foreign key)
  --%throws(-2291)
  PROCEDURE unknown_job_fails;

  --%test(Unknown employee violates foreign key)
  --%throws(-2291)
  PROCEDURE unknown_employee_fails;

  --%test(Unknown department violates foreign key)
  --%throws(-2291)
  PROCEDURE unknown_department_fails;
END test_hr_add_job_history;
/
CREATE OR REPLACE PACKAGE BODY test_hr_add_job_history AS

  c_start CONSTANT DATE := DATE '1900-01-01';
  c_end   CONSTANT DATE := DATE '1900-12-31';

  FUNCTION any_emp RETURN NUMBER IS
    l_id NUMBER;
  BEGIN
    SELECT MIN(employee_id) INTO l_id FROM employees;
    RETURN l_id;
  END;

  FUNCTION any_job RETURN VARCHAR2 IS
    l_id jobs.job_id%TYPE;
  BEGIN
    SELECT MIN(job_id) INTO l_id FROM jobs;
    RETURN l_id;
  END;

  FUNCTION any_dept RETURN NUMBER IS
    l_id NUMBER;
  BEGIN
    SELECT MIN(department_id) INTO l_id FROM departments;
    RETURN l_id;
  END;

  FUNCTION cnt(p_emp NUMBER, p_start DATE) RETURN NUMBER IS
    l_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_n FROM job_history
     WHERE employee_id = p_emp AND start_date = p_start;
    RETURN l_n;
  END;

  PROCEDURE insert_all_values IS
    l_emp  NUMBER := any_emp;
    l_job  jobs.job_id%TYPE := any_job;
    l_dept NUMBER := any_dept;
    l_end  DATE;
    l_job_r job_history.job_id%TYPE;
    l_dept_r NUMBER;
  BEGIN
    add_job_history(l_emp, c_start, c_end, l_job, l_dept);
    SELECT end_date, job_id, department_id
      INTO l_end, l_job_r, l_dept_r
      FROM job_history
     WHERE employee_id = l_emp AND start_date = c_start;
    ut.expect(l_end).to_equal(c_end);
    ut.expect(l_job_r).to_equal(l_job);
    ut.expect(l_dept_r).to_equal(l_dept);
  END;

  PROCEDURE insert_increments_count IS
    l_emp NUMBER := any_emp;
  BEGIN
    ut.expect(cnt(l_emp, c_start)).to_equal(0);
    add_job_history(l_emp, c_start, c_end, any_job, any_dept);
    ut.expect(cnt(l_emp, c_start)).to_equal(1);
  END;

  PROCEDURE null_department_allowed IS
    l_emp  NUMBER := any_emp;
    l_dept NUMBER;
  BEGIN
    add_job_history(l_emp, c_start, c_end, any_job, NULL);
    SELECT department_id INTO l_dept FROM job_history
     WHERE employee_id = l_emp AND start_date = c_start;
    ut.expect(l_dept).to_be_null();
  END;

  PROCEDURE end_one_second_after_start IS
    l_emp NUMBER := any_emp;
  BEGIN
    add_job_history(l_emp, c_start, c_start + 1/86400, any_job, any_dept);
    ut.expect(cnt(l_emp, c_start)).to_equal(1);
  END;

  PROCEDURE dates_time_portion_preserved IS
    l_emp NUMBER := any_emp;
    l_s   DATE := TO_DATE('1900-03-01 08:15:30', 'YYYY-MM-DD HH24:MI:SS');
    l_e   DATE := TO_DATE('1900-03-02 17:45:10', 'YYYY-MM-DD HH24:MI:SS');
    l_s_r DATE;
    l_e_r DATE;
  BEGIN
    add_job_history(l_emp, l_s, l_e, any_job, any_dept);
    SELECT start_date, end_date INTO l_s_r, l_e_r FROM job_history
     WHERE employee_id = l_emp AND start_date = l_s;
    ut.expect(l_s_r).to_equal(l_s);
    ut.expect(l_e_r).to_equal(l_e);
  END;

  PROCEDURE end_equals_start_fails IS
  BEGIN
    add_job_history(any_emp, c_start, c_start, any_job, any_dept);
  END;

  PROCEDURE end_before_start_fails IS
  BEGIN
    add_job_history(any_emp, c_end, c_start, any_job, any_dept);
  END;

  PROCEDURE null_employee_fails IS
  BEGIN
    add_job_history(NULL, c_start, c_end, any_job, any_dept);
  END;

  PROCEDURE null_start_date_fails IS
  BEGIN
    add_job_history(any_emp, NULL, c_end, any_job, any_dept);
  END;

  PROCEDURE null_end_date_fails IS
  BEGIN
    add_job_history(any_emp, c_start, NULL, any_job, any_dept);
  END;

  PROCEDURE null_job_fails IS
  BEGIN
    add_job_history(any_emp, c_start, c_end, NULL, any_dept);
  END;

  PROCEDURE duplicate_pk_fails IS
    l_emp NUMBER := any_emp;
  BEGIN
    add_job_history(l_emp, c_start, c_end, any_job, any_dept);
    add_job_history(l_emp, c_start, c_end, any_job, any_dept);
  END;

  PROCEDURE same_employee_other_start_ok IS
    l_emp NUMBER := any_emp;
  BEGIN
    add_job_history(l_emp, c_start, c_end, any_job, any_dept);
    add_job_history(l_emp, DATE '1901-01-01', DATE '1901-12-31', any_job, any_dept);
    ut.expect(cnt(l_emp, c_start)).to_equal(1);
    ut.expect(cnt(l_emp, DATE '1901-01-01')).to_equal(1);
  END;

  PROCEDURE unknown_job_fails IS
  BEGIN
    add_job_history(any_emp, c_start, c_end, 'ZZ_NOJOB_X', any_dept);
  END;

  PROCEDURE unknown_employee_fails IS
    l_emp NUMBER;
  BEGIN
    SELECT NVL(MAX(employee_id), 0) + 1 INTO l_emp FROM employees;
    add_job_history(l_emp, c_start, c_end, any_job, any_dept);
  END;

  PROCEDURE unknown_department_fails IS
    l_dept NUMBER;
  BEGIN
    SELECT NVL(MAX(department_id), 0) + 1 INTO l_dept FROM departments;
    add_job_history(any_emp, c_start, c_end, any_job, l_dept);
  END;

END test_hr_add_job_history;
/
