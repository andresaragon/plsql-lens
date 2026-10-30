-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_es_b AS

  FUNCTION is_blank(p_text IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF p_text = '' THEN -- expect: MIG011
      RETURN TRUE;
    END IF;
    RETURN p_text || '' IS NULL; -- expect: MIG011
  END is_blank;

END pkg_es_b;
/
