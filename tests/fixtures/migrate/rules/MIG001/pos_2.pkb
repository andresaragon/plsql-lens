-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_b AS
  c_default CONSTANT NUMBER := NVL(g_base, 10); -- expect: MIG001

  FUNCTION next_number RETURN NUMBER IS
    v_n NUMBER;
  BEGIN
    SELECT nvl (MAX(id), 0) + 1 -- expect: MIG001
      INTO v_n
      FROM orders;
    RETURN v_n;
  END next_number;

END pkg_nvl_b;
/
