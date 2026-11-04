-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_n3 AS

  PROCEDURE other_ways IS
    raise_application_error_count NUMBER := 0;
    my_raise_application_error    NUMBER;
  BEGIN
    raise_application_error_count := raise_application_error_count + 1;
    RAISE NO_DATA_FOUND;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE;
  END other_ways;

END pkg_ra_n3;
/

GRANT EXECUTE ON raise_application_error TO app_user;
