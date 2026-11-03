-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pl_n1 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'a PIPELINED function';
  BEGIN
    -- the function is no longer PIPELINED
    /* PIPELINED */
    NULL;
  END note;

END pkg_pl_n1;
/
