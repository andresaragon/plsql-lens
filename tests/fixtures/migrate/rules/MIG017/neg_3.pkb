-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pl_n3 AS

  FUNCTION list_names RETURN t_names IS
    l_out t_names := t_names();
  BEGIN
    FOR r IN (SELECT last_name FROM employees) LOOP
      l_out.EXTEND;
      l_out(l_out.COUNT) := r.last_name;
    END LOOP;
    RETURN l_out;
  END list_names;

END pkg_pl_n3;
/
