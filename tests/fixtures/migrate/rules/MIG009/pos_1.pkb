-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_a AS

  PROCEDURE hello IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE('hello'); -- expect: MIG009
  END hello;

END pkg_do_a;
/
