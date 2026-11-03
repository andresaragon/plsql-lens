-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_a AS

  PROCEDURE check_age(p_age IN NUMBER) IS
  BEGIN
    IF p_age < 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'age must not be negative'); -- expect: MIG015
    END IF;
  END check_age;

END pkg_ra_a;
/
