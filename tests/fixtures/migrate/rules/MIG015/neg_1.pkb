-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_n1 AS

  PROCEDURE qualified IS
  BEGIN
    my_pkg.raise_application_error(-20001, 'wrapped');
    other_schema.pkg_err.raise_application_error(-20002, 'wrapped');
  END qualified;

END pkg_ra_n1;
/
