-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_c AS

  PROCEDURE greet(p_prefix IN VARCHAR2 DEFAULT '', -- expect: MIG011
                  p_name IN NVARCHAR2 DEFAULT n'') IS -- expect: MIG011
  BEGIN
    UPDATE people SET nick = '' WHERE id = 1; -- expect: MIG011
  END greet;

END pkg_es_c;
/
