-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_c AS

  PROCEDURE a IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20010, 'a'); -- expect: MIG015
  END a;

  PROCEDURE b IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20011, 'b'); -- expect: MIG015
  END b;

END pkg_ra_c;
/
