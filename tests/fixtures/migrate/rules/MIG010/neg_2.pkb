-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_du_n2 AS

  FUNCTION one RETURN NUMBER IS
    v_n NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_n FROM dual_log;
    SELECT COUNT(*) INTO v_n FROM my_dual;
    RETURN v_n;
  END one;

END pkg_du_n2;
/
