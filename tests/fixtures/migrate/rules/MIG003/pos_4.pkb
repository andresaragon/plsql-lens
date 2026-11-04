-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_d AS

  PROCEDURE wait_seconds(p_seconds IN NUMBER) IS
    l_now      TIMESTAMP := SYSTIMESTAMP; -- expect: MIG003
    l_deadline TIMESTAMP;
  BEGIN
    l_deadline := l_now + NUMTODSINTERVAL(p_seconds, 'SECOND');
    WHILE l_now < l_deadline LOOP
      l_now := SYSTIMESTAMP; -- expect: MIG003
    END LOOP;
  END wait_seconds;

END pkg_sd_d;
/
