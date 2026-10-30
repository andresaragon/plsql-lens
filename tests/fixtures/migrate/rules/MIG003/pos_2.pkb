-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_b AS

  PROCEDURE stamp(p_out OUT TIMESTAMP) IS
  BEGIN
    p_out := systimestamp; -- expect: MIG003
  END stamp;

END pkg_sd_b;
/
