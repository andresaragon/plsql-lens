-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_n3 AS

  PROCEDURE stamp(p_out OUT TIMESTAMP) IS
  BEGIN
    -- the old code used SYSDATE here
    /* systimestamp is not used any more */
    p_out := LOCALTIMESTAMP;
  END stamp;

END pkg_sd_n3;
/
