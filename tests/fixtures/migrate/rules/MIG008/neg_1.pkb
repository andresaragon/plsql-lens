-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_n1 AS

  PROCEDURE p(p_code IN NUMBER) IS
    e_bad EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bad, -20001);
  BEGIN
    NULL;
  END p;

END pkg_at_n1;
/
