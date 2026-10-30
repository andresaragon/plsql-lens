-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_n2 AS

  PROCEDURE walk(p_rec IN items%ROWTYPE) IS
    v_rownum_total NUMBER := 0;
    v_rownumber NUMBER := 0;
  BEGIN
    v_rownum_total := p_rec.rownum + v_rownumber;
  END walk;

END pkg_rn_n2;
/
