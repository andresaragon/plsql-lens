-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_c AS

  PROCEDURE two IS
  BEGIN
    execute immediate 'BEGIN pkg_x.run(:name); END;' USING 'a'; -- expect: MIG014
    Execute Immediate 'ALTER SESSION SET NLS_DATE_FORMAT = ''YYYY-MM-DD'''; -- expect: MIG014
  END two;

END pkg_ei_c;
/
