-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_a AS

  PROCEDURE first_row(p_id OUT NUMBER) IS
  BEGIN
    SELECT id INTO p_id FROM orders WHERE ROWNUM = 1; -- expect: MIG005
  END first_row;

END pkg_rn_a;
/
