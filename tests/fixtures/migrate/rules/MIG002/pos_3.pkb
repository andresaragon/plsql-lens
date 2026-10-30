-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_dec_c AS

  PROCEDURE report IS
    v_text VARCHAR2(30);
  BEGIN
    SELECT DECODE(status, 'A', 'Active', 'I', 'Inactive', 'Unknown') -- expect: MIG002
      INTO v_text
      FROM accounts
     WHERE id = 1;
    v_text := decode (v_text, 'x', 'y', NULL); -- expect: MIG002
  END report;

END pkg_dec_c;
/
