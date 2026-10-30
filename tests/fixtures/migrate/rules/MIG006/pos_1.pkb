-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_a AS

  PROCEDURE tree IS
  BEGIN
    FOR r IN (SELECT id, parent_id FROM nodes
               START WITH parent_id IS NULL
             CONNECT BY PRIOR id = parent_id) LOOP -- expect: MIG006
      NULL;
    END LOOP;
  END tree;

END pkg_cb_a;
/
