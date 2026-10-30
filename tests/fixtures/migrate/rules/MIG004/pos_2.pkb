-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_b AS

  FUNCTION last_id RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    v_id := hr.seq_emp.CURRVAL; -- expect: MIG004
    RETURN v_id;
  END last_id;

END pkg_seq_b;
/
