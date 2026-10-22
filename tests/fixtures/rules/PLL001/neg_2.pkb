-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_billing_run AS

  PROCEDURE run_cycle(p_cycle_id IN NUMBER, p_message OUT VARCHAR2) IS
  BEGIN
    pkg_billing_core.execute_cycle(p_cycle_id);
    p_message := 'OK';
  EXCEPTION
    WHEN OTHERS THEN
      p_message := 'Cycle failed: ' || SQLERRM;
  END run_cycle;

  FUNCTION last_error_code(p_cycle_id IN NUMBER) RETURN NUMBER IS
  BEGIN
    pkg_billing_core.verify_cycle(p_cycle_id);
    RETURN 0;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN SQLCODE;
  END last_error_code;

  PROCEDURE close_cycle(p_cycle_id IN NUMBER, p_detail OUT VARCHAR2) IS
  BEGIN
    pkg_billing_core.finish_cycle(p_cycle_id);
  EXCEPTION
    WHEN OTHERS THEN
      p_detail := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  END close_cycle;

END pkg_billing_run;
/
