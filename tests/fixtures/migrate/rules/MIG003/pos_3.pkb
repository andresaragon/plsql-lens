-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_c AS
  g_started DATE := SYSDATE; -- expect: MIG003

  PROCEDURE purge IS
  BEGIN
    DELETE FROM audit_log
     WHERE created_at < sysdate - 30; -- expect: MIG003
    UPDATE jobs SET seen_at = SYSTIMESTAMP WHERE id = 1; -- expect: MIG003
  END purge;

END pkg_sd_c;
/
