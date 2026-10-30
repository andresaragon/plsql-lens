-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_n1 AS

  PROCEDURE tree IS
  BEGIN
    FOR r IN (WITH RECURSIVE t AS (SELECT 1) SELECT * FROM t) LOOP
      NULL;
    END LOOP;
  END tree;

END pkg_cb_n1;
/
