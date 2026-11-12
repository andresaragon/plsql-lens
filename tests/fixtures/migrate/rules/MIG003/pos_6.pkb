-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_f AS

  PROCEDURE wait_until(p_deadline IN TIMESTAMP) IS
  BEGIN
    WHILE SYSTIMESTAMP < p_deadline LOOP -- expect: MIG003
      NULL;
    END LOOP;
  END wait_until;

END pkg_sd_f;
/
