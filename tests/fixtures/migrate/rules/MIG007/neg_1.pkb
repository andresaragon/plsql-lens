-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_n1 AS

  PROCEDURE join_new IS
  BEGIN
    FOR r IN (SELECT a.id FROM a LEFT JOIN b ON a.id = b.id) LOOP
      NULL;
    END LOOP;
  END join_new;

END pkg_oj_n1;
/
