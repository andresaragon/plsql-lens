-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_sev_neg AS

  FUNCTION fine(p_text IN VARCHAR2) RETURN VARCHAR2 IS
    v_out VARCHAR2(200);
  BEGIN
    v_out := replace(p_text, ' ', '_');
    v_out := regexp_replace(v_out, 'a', ' ');
    v_out := v_out || 'x' || ' ';
    v_out := nvl(v_out, 'none');
    RETURN v_out;
  END fine;

END pkg_sev_neg;
/
