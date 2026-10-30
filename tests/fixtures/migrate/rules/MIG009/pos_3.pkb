-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_c AS

  PROCEDURE hello(p_text IN VARCHAR2) IS
  BEGIN
    dbms_output.enable(1000000); -- expect: MIG009
    IF p_text IS NOT NULL THEN
      dbms_output -- expect: MIG009
        .put_line(p_text);
    END IF;
  END hello;

END pkg_do_c;
/
