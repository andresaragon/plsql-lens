-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_label_format AS

  FUNCTION join_ids(p_a IN NUMBER, p_b IN NUMBER, p_c IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN p_a || ',' || p_b || ',' || p_c;
  END join_ids;

  FUNCTION join_path(p_dir IN VARCHAR2, p_file IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN '/' || p_dir || '/' || p_file || '/';
  END join_path;

  FUNCTION clean_label(p_label IN VARCHAR2) RETURN VARCHAR2 IS
    l_out VARCHAR2(100);
  BEGIN
    l_out := REPLACE(p_label, '-', '');
    l_out := REPLACE(l_out, '_', '');
    l_out := REPLACE(l_out, '.', '');
    IF l_out IS NULL THEN
      RETURN '';
    END IF;
    RETURN l_out;
  END clean_label;

  FUNCTION fallback_label(p_label IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    IF p_label IS NULL THEN
      RETURN 'n/a';
    ELSIF LENGTH(p_label) = 0 THEN
      RETURN 'n/a';
    END IF;
    RETURN p_label;
  END fallback_label;

END pkg_label_format;
/
