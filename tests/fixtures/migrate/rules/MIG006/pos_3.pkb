-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_c AS

  PROCEDURE levels IS
  BEGIN
    FOR r IN (SELECT LEVEL lv FROM dual
              CONNECT -- expect: MIG006
                BY LEVEL <= 5) LOOP
      NULL;
    END LOOP;
  END levels;

END pkg_cb_c;
/
