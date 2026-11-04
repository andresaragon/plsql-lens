-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_n1 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'we used BULK COLLECT here';
  BEGIN
    -- BULK COLLECT was replaced by a loop
    /* BULK COLLECT INTO l_ids */
    NULL;
  END note;

END pkg_bc_n1;
/
