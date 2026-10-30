-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sev_cat AS

  FUNCTION label(p_name IN VARCHAR2, p_code IN VARCHAR2) RETURN VARCHAR2 IS
    v_label VARCHAR2(100);
  BEGIN
    v_label := p_name || ''; -- expect: MIG011 info
    v_label := '' || p_code; -- expect: MIG011 info
    v_label := 'a' || '' || 'b'; -- expect: MIG011 info
    v_label := p_name
      ||
      ''; -- expect: MIG011 info
    v_label := replace(p_name, 'a', '' || 'x'); -- expect: MIG011 info
    RETURN v_label;
  END label;

END pkg_sev_cat;
/
