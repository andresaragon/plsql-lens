-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_a AS

  PROCEDURE join_old IS
  BEGIN
    FOR r IN (SELECT a.id, b.name
                FROM a, b
               WHERE a.id = b.id(+)) LOOP -- expect: MIG007
      NULL;
    END LOOP;
  END join_old;

END pkg_oj_a;
/
