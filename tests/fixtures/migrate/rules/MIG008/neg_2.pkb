-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_n2 AS
  PRAGMA SERIALLY_REUSABLE;

  PROCEDURE p IS
    v_autonomous_transaction NUMBER := 0;
  BEGIN
    v_autonomous_transaction := v_autonomous_transaction + 1;
  END p;

END pkg_at_n2;
/
