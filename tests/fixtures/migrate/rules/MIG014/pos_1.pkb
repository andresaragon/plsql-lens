-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_a AS

  PROCEDURE clean IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE staging'; -- expect: MIG014
  END clean;

END pkg_ei_a;
/
