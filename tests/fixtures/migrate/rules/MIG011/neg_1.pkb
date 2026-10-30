-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_n1 AS

  PROCEDURE clear(p_name OUT VARCHAR2) IS
  BEGIN
    p_name := NULL;
    p_name := ' ';
    p_name := 'a';
  END clear;

END pkg_es_n1;
/
