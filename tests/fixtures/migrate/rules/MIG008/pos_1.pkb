-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_a AS

  PROCEDURE log_it(p_msg IN VARCHAR2) IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- expect: MIG008
  BEGIN
    INSERT INTO app_log (msg) VALUES (p_msg);
    COMMIT;
  END log_it;

END pkg_at_a;
/
