-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_n3 AS

  PROCEDURE note IS
    v_sql VARCHAR2(100) := 'where a.id = b.id(+)';
  BEGIN
    -- WHERE a.id = b.id(+)
    /* b.id (+) */
    NULL;
  END note;

END pkg_oj_n3;
/
