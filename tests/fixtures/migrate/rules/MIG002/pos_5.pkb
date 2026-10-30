-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dsev_med AS

  FUNCTION same(a IN ut_row, b IN ut_row, p_x IN NUMBER, p_limit IN NUMBER) RETURN NUMBER IS
    v_n NUMBER;
  BEGIN
    v_n := DECODE(a.val, b.val, 1, 0); -- expect: MIG002 medium
    v_n := decode(p_x, p_limit, 1, 2); -- expect: MIG002 medium
    v_n := DECODE(p_x, 1, 10, p_limit, 20, 30); -- expect: MIG002 medium
    v_n := DECODE(p_x, NULL, 0, 1); -- expect: MIG002 medium
    v_n := DECODE(p_x, 1 + 1, 2); -- expect: MIG002 medium
    v_n := DECODE(p_x, f(1), 2); -- expect: MIG002 medium
    v_n := DECODE(p_x, -p_limit, 2); -- expect: MIG002 medium
    RETURN v_n;
  END same;

END pkg_dsev_med;
/
