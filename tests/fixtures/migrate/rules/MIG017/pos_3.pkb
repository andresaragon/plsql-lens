-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pl_c AS

  FUNCTION a RETURN t_rows
    PARALLEL_ENABLE
    PIPELINED -- expect: MIG017
  IS
  BEGIN
    RETURN;
  END a;

  FUNCTION b RETURN t_rows PIPELINED IS -- expect: MIG017
  BEGIN
    RETURN;
  END b;

END pkg_pl_c;
/
