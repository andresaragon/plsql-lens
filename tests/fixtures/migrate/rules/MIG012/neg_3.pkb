-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_n3 AS

  PROCEDURE one_by_one IS
  BEGIN
    FOR r IN (SELECT employee_id FROM employees) LOOP
      process_row(r.employee_id);
    END LOOP;
  END one_by_one;

END pkg_bc_n3;
/
