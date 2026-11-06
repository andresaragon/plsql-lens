-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_n4 AS

  PROCEDURE wait_seconds(p_seconds IN NUMBER) IS
    l_deadline TIMESTAMP := LOCALTIMESTAMP + NUMTODSINTERVAL(p_seconds, 'SECOND');
  BEGIN
    -- the loop used to re-read SYSTIMESTAMP on every pass
    WHILE LOCALTIMESTAMP < l_deadline LOOP
      NULL;
    END LOOP;
    DBMS_SESSION.SLEEP(1); /* instead of a busy wait on sysdate */
    sysdate_report('sysdate and systimestamp');
    pkg_clock.sysdate_value := clock_timestamp_ish;
  END wait_seconds;

END pkg_sd_n4;
/
