-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_n3 AS

  PROCEDURE note IS
    v_text VARCHAR2(60) := 'PRAGMA AUTONOMOUS_TRANSACTION;';
  BEGIN
    -- PRAGMA AUTONOMOUS_TRANSACTION;
    /* pragma autonomous_transaction */
    NULL;
  END note;

END pkg_at_n3;
/
