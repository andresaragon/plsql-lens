-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_c AS

  PROCEDURE pick(p_a IN NUMBER, p_b IN NUMBER, p_c IN NUMBER, p_out OUT NUMBER) IS
  BEGIN
    p_out := nvl(nvl(p_a, p_b), p_c); -- expect: MIG001
    UPDATE items
       SET qty = NVL(qty, 0) + 1 -- expect: MIG001
     WHERE id = p_a;
  END pick;

END pkg_nvl_c;
/
