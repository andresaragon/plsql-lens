-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_c AS

  PROCEDURE first_pass(p_ids IN t_ids) IS
  BEGIN
    FORALL i IN p_ids.FIRST .. p_ids.LAST UPDATE t SET n = n + 1 WHERE id = p_ids(i); -- expect: MIG013
  END first_pass;

  PROCEDURE second_pass(p_ids IN t_ids) IS
  BEGIN
    FORALL j IN VALUES OF p_ids -- expect: MIG013
      DELETE FROM t WHERE id = p_ids(j);
  END second_pass;

END pkg_fa_c;
/
