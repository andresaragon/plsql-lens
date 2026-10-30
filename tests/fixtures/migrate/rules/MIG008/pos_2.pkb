-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_at_b AS

  FUNCTION audit(p_id IN NUMBER) RETURN NUMBER IS
    pragma autonomous_transaction; -- expect: MIG008
  BEGIN
    UPDATE audit_trail SET seen = 1 WHERE id = p_id;
    COMMIT;
    RETURN 1;
  END audit;

END pkg_at_b;
/
