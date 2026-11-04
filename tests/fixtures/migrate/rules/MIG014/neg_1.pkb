-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_n1 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'EXECUTE IMMEDIATE is dynamic SQL';
  BEGIN
    -- EXECUTE IMMEDIATE is not used here
    /* EXECUTE IMMEDIATE 'x' */
    NULL;
  END note;

END pkg_ei_n1;
/
