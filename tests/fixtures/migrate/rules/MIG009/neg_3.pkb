-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_n3 AS

  PROCEDURE note IS
    v_text VARCHAR2(80) := 'dbms_output.put_line(''x'')';
  BEGIN
    -- DBMS_OUTPUT.PUT_LINE('x');
    /* sys.dbms_output.put_line('y'); */
    NULL;
  END note;

END pkg_do_n3;
/
