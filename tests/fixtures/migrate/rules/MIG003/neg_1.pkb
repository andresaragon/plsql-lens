-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_n1 AS

  PROCEDURE stamp(p_out OUT DATE) IS
  BEGIN
    p_out := CURRENT_DATE;
  END stamp;

END pkg_sd_n1;
/
