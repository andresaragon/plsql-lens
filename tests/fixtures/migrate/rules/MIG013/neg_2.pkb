-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_n2 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'FORALL i IN 1 .. 10';
  BEGIN
    -- FORALL was replaced by a plain loop
    /* FORALL i IN 1 .. 10 INSERT ... */
    NULL;
  END note;

END pkg_fa_n2;
/
