-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_e AS

  FUNCTION elapsed_ms(p_start IN TIMESTAMP) RETURN NUMBER IS
  BEGIN
    LOOP
      EXIT WHEN systimestamp - p_start > INTERVAL '2' SECOND; -- expect: MIG003
    END LOOP;
    RETURN EXTRACT(SECOND FROM (systimestamp - p_start)) * 1000; -- expect: MIG003
  END elapsed_ms;

END pkg_sd_e;
/
