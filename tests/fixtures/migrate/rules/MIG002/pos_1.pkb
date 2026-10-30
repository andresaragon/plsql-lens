-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_a AS

  FUNCTION flag_to_num(p_flag IN VARCHAR2) RETURN NUMBER IS
  BEGIN
    RETURN DECODE(p_flag, 'Y', 1, 0); -- expect: MIG002
  END flag_to_num;

END pkg_dec_a;
/
