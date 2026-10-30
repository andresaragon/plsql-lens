-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_n2 AS

  PROCEDURE walk(p_rec IN items%ROWTYPE) IS
    v_nextval NUMBER := 0;
    v_date DATE;
  BEGIN
    v_date := p_rec.nextval_date;
    v_nextval := v_nextval + 1;
  END walk;

END pkg_seq_n2;
/
