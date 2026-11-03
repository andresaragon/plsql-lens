-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_fa_n3 AS

  PROCEDURE plain_loop(p_ids IN t_ids) IS
  BEGIN
    FOR i IN 1 .. p_ids.COUNT LOOP
      INSERT INTO audit_log (id) VALUES (p_ids(i));
    END LOOP;
  END plain_loop;

END pkg_fa_n3;
/
