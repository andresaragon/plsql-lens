-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ei_n3 AS

  PROCEDURE names IS
    execute_count NUMBER := 0;
    immediate_flag BOOLEAN := FALSE;
  BEGIN
    execute_count := execute_count + 1;
    EXECUTE pkg_other.run_it;
  END names;

END pkg_ei_n3;
/
