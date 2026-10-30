-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_rn_b AS

  PROCEDURE top_ten IS
  BEGIN
    FOR r IN (SELECT id FROM orders WHERE rownum <= 10) LOOP -- expect: MIG005
      NULL;
    END LOOP;
  END top_ten;

END pkg_rn_b;
/
