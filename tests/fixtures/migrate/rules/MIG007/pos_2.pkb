-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_oj_b AS

  PROCEDURE join_old IS
  BEGIN
    FOR r IN (SELECT a.id
                FROM a, b
               WHERE a.id = b.id (+) -- expect: MIG007
                 AND b.kind(+) = 'X') LOOP -- expect: MIG007
      NULL;
    END LOOP;
  END join_old;

END pkg_oj_b;
/
