-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_c AS

  PROCEDURE numbered IS
  BEGIN
    FOR r IN (SELECT ROWNUM rn, -- expect: MIG005
                     name
                FROM customers) LOOP
      NULL;
    END LOOP;
  END numbered;

END pkg_rn_c;
/
