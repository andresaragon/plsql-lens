-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_b AS

  PROCEDURE save_some(p_ids IN t_ids) IS
  BEGIN
    forall i in indices of p_ids save exceptions -- expect: MIG013
      DELETE FROM audit_log WHERE id = p_ids(i);
  END save_some;

END pkg_fa_b;
/
