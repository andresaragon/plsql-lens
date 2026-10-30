-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_do_n1 AS

  PROCEDURE hello(p_text IN VARCHAR2) IS
  BEGIN
    RAISE NOTICE 'hello %', p_text;
  END hello;

END pkg_do_n1;
/
