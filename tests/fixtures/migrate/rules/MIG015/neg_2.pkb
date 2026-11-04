-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_n2 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'RAISE_APPLICATION_ERROR(-20001, ''x'')';
  BEGIN
    -- RAISE_APPLICATION_ERROR(-20001, 'x') was removed
    /* raise_application_error(-20002, 'y'); */
    NULL;
  END note;

END pkg_ra_n2;
/
