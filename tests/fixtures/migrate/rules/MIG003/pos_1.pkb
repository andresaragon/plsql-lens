-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_a AS

  PROCEDURE stamp(p_out OUT DATE) IS
  BEGIN
    p_out := SYSDATE; -- expect: MIG003
  END stamp;

END pkg_sd_a;
/
