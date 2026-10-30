-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_du_n1 AS

  FUNCTION one RETURN NUMBER IS
    v_n NUMBER;
  BEGIN
    SELECT 1 INTO v_n;
    RETURN v_n;
  END one;

END pkg_du_n1;
/
