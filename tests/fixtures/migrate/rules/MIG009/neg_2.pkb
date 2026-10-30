-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_n2 AS

  PROCEDURE hello(p_text IN VARCHAR2) IS
  BEGIN
    util_dbms_output.put_line(p_text);
    my_app.dbms_output.put_line(p_text);
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON dbms_output TO app_user';
  END hello;

END pkg_do_n2;
/
