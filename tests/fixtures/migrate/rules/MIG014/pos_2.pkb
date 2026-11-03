-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_b AS

  FUNCTION count_rows(p_table IN VARCHAR2) RETURN NUMBER IS
    l_sql VARCHAR2(200);
    l_n   NUMBER;
  BEGIN
    l_sql := 'SELECT COUNT(*) FROM ' || p_table || ' WHERE id > :1';
    EXECUTE -- expect: MIG014
      IMMEDIATE l_sql INTO l_n USING 10;
    RETURN l_n;
  END count_rows;

END pkg_ei_b;
/
