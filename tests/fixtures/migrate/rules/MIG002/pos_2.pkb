-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_b AS

  FUNCTION label(p_x IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN decode(p_x, NULL, 'none', 'some'); -- expect: MIG002
  END label;

END pkg_dec_b;
/
