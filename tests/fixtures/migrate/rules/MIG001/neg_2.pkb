-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_nvl_n2 AS

  PROCEDURE total_of(p_a IN NUMBER, p_out OUT NUMBER) IS
    v_nvl_count PLS_INTEGER := 0;
  BEGIN
    p_out := my_helpers.nvl(p_a, 0);
    v_nvl_count := v_nvl_count + 1;
  END total_of;

END pkg_nvl_n2;
/
