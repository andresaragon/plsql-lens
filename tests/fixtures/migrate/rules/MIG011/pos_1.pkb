-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_a AS

  PROCEDURE clear(p_name OUT VARCHAR2) IS
  BEGIN
    p_name := ''; -- expect: MIG011
  END clear;

END pkg_es_a;
/
