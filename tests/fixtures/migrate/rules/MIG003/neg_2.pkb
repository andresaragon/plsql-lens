-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sd_n2 AS

  PROCEDURE stamp(p_out OUT NUMBER) IS
    v_sysdate_offset NUMBER := 1;
    v_msg VARCHAR2(60) := 'SYSDATE and SYSTIMESTAMP are Oracle only';
  BEGIN
    p_out := v_sysdate_offset;
  END stamp;

END pkg_sd_n2;
/
