-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sev_rep AS

  FUNCTION clean(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    v_out VARCHAR2(200);
  BEGIN
    v_out := replace(p_text, ' ', ''); -- expect: MIG011 medium
    v_out := REGEXP_REPLACE(v_out, '[0-9]', ''); -- expect: MIG011 medium
    v_out := regexp_replace(v_out, 'x', '', 1, 0, 'i'); -- expect: MIG011 medium
    v_out := replace(trim(v_out), 'a',
                     ''); -- expect: MIG011 medium
    v_out := regexp_replace(v_out, 'a', n''); -- expect: MIG011 medium
    RETURN v_out;
  END clean;

END pkg_sev_rep;
/
