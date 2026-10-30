-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dsev_neg AS

  FUNCTION same(a IN ut_row, b IN ut_row) RETURN NUMBER IS
    v_n NUMBER;
  BEGIN
    v_n := CASE WHEN a.val IS NOT DISTINCT FROM b.val THEN 1 ELSE 0 END;
    v_n := CASE a.val WHEN 1 THEN 10 ELSE 20 END;
    v_n := my_pkg.decode(a.val, b.val, 1, 0);
    RETURN v_n;
  END same;

END pkg_dsev_neg;
/
