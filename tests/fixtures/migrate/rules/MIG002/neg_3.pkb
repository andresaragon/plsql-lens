-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_n3 AS

  PROCEDURE note IS
    v_text VARCHAR2(100) := 'DECODE(a, 1, 2) is Oracle only';
  BEGIN
    -- DECODE(a, 1, 2)
    /* decode(x, null, 1) */
    v_text := v_text || ' done';
  END note;

END pkg_dec_n3;
/
