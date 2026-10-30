-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_b AS

  PROCEDURE hello IS
  BEGIN
    sys.dbms_output.put_line('hello'); -- expect: MIG009
    dbms_output.new_line; -- expect: MIG009
  END hello;

END pkg_do_b;
/
