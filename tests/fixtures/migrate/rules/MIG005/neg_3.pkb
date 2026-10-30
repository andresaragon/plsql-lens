-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_n3 AS

  PROCEDURE note IS
    v_sql VARCHAR2(100) := 'select * from t where rownum < 5';
  BEGIN
    -- WHERE ROWNUM = 1
    /* rownum */
    NULL;
  END note;

END pkg_rn_n3;
/
