-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_n3 AS

  PROCEDURE note IS
    v_text VARCHAR2(100) := 'use NVL(a, b) for defaults';
  BEGIN
    -- NVL(a, b) is flagged elsewhere
    /* nvl(x, 0) in a block comment */
    SELECT nvl INTO v_text FROM settings;
  END note;

END pkg_nvl_n3;
/
