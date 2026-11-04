-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_b AS

  PROCEDURE run_dynamic(p_sql IN VARCHAR2) IS
    l_cur NUMBER;
    l_n   NUMBER;
  BEGIN
    l_cur := dbms_sql.open_cursor; -- expect: MIG016 high
    dbms_sql.parse(l_cur, p_sql, dbms_sql.native); -- expect: MIG016 high
    l_n := SYS.DBMS_SQL.EXECUTE(l_cur); -- expect: MIG016 high
    dbms_sql.close_cursor(l_cur); -- expect: MIG016 high
  END run_dynamic;

END pkg_pk_b;
/
