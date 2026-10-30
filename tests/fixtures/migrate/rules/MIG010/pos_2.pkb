-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_du_b AS

  FUNCTION today RETURN VARCHAR2 IS
    v_d VARCHAR2(10);
  BEGIN
    SELECT 'x'
      INTO v_d
      FROM
        dual; -- expect: MIG010
    RETURN v_d;
  END today;

END pkg_du_b;
/
