-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sev_high AS

  FUNCTION odd(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    v_out VARCHAR2(200) := ''; -- expect: MIG011 high
  BEGIN
    v_out := replace(p_text, '', 'x'); -- expect: MIG011 high
    v_out := regexp_replace('', 'a', 'b'); -- expect: MIG011 high
    v_out := my_pkg.replace(p_text, 'a', ''); -- expect: MIG011 high
    v_out := translate(p_text, 'a', ''); -- expect: MIG011 high
    v_out := nvl(replace(p_text, 'a', 'b'), ''); -- expect: MIG011 high
    v_out := replace(p_text, 'a', ('')); -- expect: MIG011 high
    v_out := replace(p_text, ''); -- expect: MIG011 high
    IF v_out IS NULL THEN
      v_out := ''; -- expect: MIG011 high
    END IF;
    RETURN v_out;
  END odd;

END pkg_sev_high;
/
