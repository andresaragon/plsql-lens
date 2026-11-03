-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_a AS

  PROCEDURE save_all(p_ids IN t_ids) IS
  BEGIN
    FORALL i IN 1 .. p_ids.COUNT -- expect: MIG013
      INSERT INTO audit_log (id) VALUES (p_ids(i));
  END save_all;

END pkg_fa_a;
/
