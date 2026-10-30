-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_n2 AS

  PROCEDURE quote(p_out OUT VARCHAR2) IS
  BEGIN
    p_out := '''';
    p_out := 'it''s';
    p_out := 'select '''' from t';
  END quote;

END pkg_es_n2;
/
