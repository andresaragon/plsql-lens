-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_n1 AS

  PROCEDURE total_of(p_a IN NUMBER, p_b IN NUMBER, p_out OUT NUMBER) IS
  BEGIN
    p_out := NVL2(p_a, p_a, p_b);
    p_out := p_out + 1;
  END total_of;

END pkg_nvl_n1;
/
