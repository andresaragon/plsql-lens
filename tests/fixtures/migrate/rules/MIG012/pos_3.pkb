-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_c AS

  PROCEDURE purge(p_dept IN NUMBER) IS
    TYPE t_ids IS TABLE OF NUMBER;
    l_gone t_ids;
  BEGIN
    DELETE FROM employees WHERE department_id = p_dept
      RETURNING employee_id bulk collect INTO l_gone; -- expect: MIG012
    EXECUTE IMMEDIATE 'SELECT id FROM t' BULK COLLECT INTO l_gone; -- expect: MIG012
  END purge;

END pkg_bc_c;
/
