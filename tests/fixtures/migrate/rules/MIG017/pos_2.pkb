-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pl_b AS

  FUNCTION list_names(p_dept IN NUMBER) RETURN t_names pipelined IS -- expect: MIG017
  BEGIN
    FOR r IN (SELECT last_name FROM employees WHERE department_id = p_dept) LOOP
      PIPE ROW (r.last_name);
    END LOOP;
    RETURN;
  END list_names;

END pkg_pl_b;
/
