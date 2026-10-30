-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_n2 AS

  FUNCTION calc(p_a IN NUMBER, p_b IN NUMBER) RETURN NUMBER IS
  BEGIN
    RETURN (p_a + p_b) * (+ p_a) + (1 + 2);
  END calc;

END pkg_oj_n2;
/
