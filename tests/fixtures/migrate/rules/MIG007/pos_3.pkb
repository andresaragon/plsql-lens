-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_c AS

  PROCEDURE join_old IS
  BEGIN
    FOR r IN (SELECT a.id
                FROM a, b
               WHERE b.id
                 ( + ) = a.id) LOOP -- expect: MIG007
      NULL;
    END LOOP;
  END join_old;

END pkg_oj_c;
/
