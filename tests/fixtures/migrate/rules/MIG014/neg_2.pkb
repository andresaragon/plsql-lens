-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_n2 AS

  PROCEDURE with_dbms_sql(p_cur IN NUMBER) IS
    l_n NUMBER;
  BEGIN
    l_n := dbms_sql.execute(p_cur);
  END with_dbms_sql;

END pkg_ei_n2;
/

GRANT EXECUTE ON pkg_ei_n2 TO app_user;
