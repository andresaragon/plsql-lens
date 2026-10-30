-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_n3 AS

  PROCEDURE note IS
    v_text VARCHAR2(60) := 'an empty literal is ''''';
  BEGIN
    -- v_text := '';
    /* x := ''; */
    v_text := q'[no]';
  END note;

END pkg_es_n3;
/
