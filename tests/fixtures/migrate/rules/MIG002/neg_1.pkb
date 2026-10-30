-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_n1 AS

  FUNCTION label(p_x IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE p_x WHEN 'Y' THEN 'yes' ELSE 'no' END;
  END label;

END pkg_dec_n1;
/
