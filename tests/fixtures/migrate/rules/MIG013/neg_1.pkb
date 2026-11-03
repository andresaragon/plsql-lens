-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_n1 AS

  PROCEDURE counters IS
    forall_count NUMBER := 0;
    l_forall     NUMBER;
    forall2      NUMBER;
  BEGIN
    forall_count := forall_count + 1;
    l_forall := forall_count;
  END counters;

END pkg_fa_n1;
/
