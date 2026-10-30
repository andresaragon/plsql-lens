-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_a AS

  PROCEDURE total_of(p_amount IN NUMBER, p_out OUT NUMBER) IS
  BEGIN
    p_out := NVL(p_amount, 0); -- expect: MIG001
  END total_of;

END pkg_nvl_a;
/
