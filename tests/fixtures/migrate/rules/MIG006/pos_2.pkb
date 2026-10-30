-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_b AS

  PROCEDURE tree IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count
      FROM emp
     START WITH mgr IS NULL
     connect by nocycle prior empno = mgr; -- expect: MIG006
  END tree;

END pkg_cb_b;
/
