-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_n3 AS

  PROCEDURE note IS
    v_sql VARCHAR2(200) := 'select 1 from dual connect by level < 3';
  BEGIN
    -- CONNECT BY PRIOR id = parent_id
    /* connect by */
    NULL;
  END note;

END pkg_cb_n3;
/
