-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pl_n2 AS

  PROCEDURE names IS
    pipelined_count NUMBER := 0;
    l_pipelined_on  BOOLEAN := FALSE;
  BEGIN
    pipelined_count := pipelined_count + 1;
  END names;

END pkg_pl_n2;
/
