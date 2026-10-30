-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_c AS

  PROCEDURE one IS
    v_x NUMBER;
    PRAGMA -- expect: MIG008
      AUTONOMOUS_TRANSACTION;
  BEGIN
    v_x := 1;
    ROLLBACK;
  END one;
  PROCEDURE two IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- expect: MIG008
  BEGIN
    NULL;
  END two;

END pkg_at_c;
/
