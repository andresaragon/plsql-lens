-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_du_c AS

  PROCEDURE two IS
    v_a NUMBER;
    v_b NUMBER;
  BEGIN
    SELECT 1 INTO v_a FROM dual; -- expect: MIG010
    SELECT 2 INTO v_b FROM sys.dual; -- not matched: schema prefix
    SELECT 3 INTO v_b FROM dual d; -- expect: MIG010
  END two;

END pkg_du_c;
/
