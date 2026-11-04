-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_a AS

  PROCEDURE load_ids IS
    TYPE t_ids IS TABLE OF NUMBER;
    l_ids t_ids;
  BEGIN
    SELECT employee_id BULK COLLECT INTO l_ids -- expect: MIG012
      FROM employees;
  END load_ids;

END pkg_bc_a;
/
