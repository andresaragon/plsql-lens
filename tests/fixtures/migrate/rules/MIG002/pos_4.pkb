-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dsev_low AS

  FUNCTION literal_codes(p_code IN NUMBER, p_flag IN VARCHAR2, p_x IN NUMBER) RETURN VARCHAR2 IS
    v_a VARCHAR2(20);
  BEGIN
    v_a := DECODE(p_code, 1, 'a', -2, 'b', 'c'); -- expect: MIG002 low
    v_a := decode(p_flag, '+1', 1, '-', 2, 0); -- expect: MIG002 low
    v_a := DECODE(p_x, +5, 'p'); -- expect: MIG002 low
    v_a := DECODE(p_x, - 1, 'neg', 'other'); -- expect: MIG002 low
    v_a := DECODE(p_x, 1, 'a', p_code); -- expect: MIG002 low
    v_a := DECODE(p_x, 1, p_flag, 2, p_code); -- expect: MIG002 low
    RETURN v_a;
  END literal_codes;

END pkg_dsev_low;
/
