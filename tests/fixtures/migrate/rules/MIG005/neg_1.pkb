-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_n1 AS

  PROCEDURE first_row(p_id OUT NUMBER) IS
  BEGIN
    SELECT id INTO p_id FROM orders FETCH FIRST 1 ROWS ONLY;
  END first_row;

END pkg_rn_n1;
/
