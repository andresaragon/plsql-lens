-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_n2 AS

  FUNCTION label(p_x IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN pkg_codec.decode(p_x);
  END label;
  FUNCTION decoded_value(p_x IN VARCHAR2) RETURN VARCHAR2 IS
    v_decode VARCHAR2(10) := p_x;
  BEGIN
    RETURN v_decode;
  END decoded_value;

END pkg_dec_n2;
/
