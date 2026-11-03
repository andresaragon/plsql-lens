-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_a AS

  PROCEDURE write_report(p_dir IN VARCHAR2, p_name IN VARCHAR2) IS
    l_file UTL_FILE.FILE_TYPE; -- expect: MIG016 high
  BEGIN
    l_file := UTL_FILE.FOPEN(p_dir, p_name, 'w'); -- expect: MIG016 high
    UTL_FILE.PUT_LINE(l_file, 'report'); -- expect: MIG016 high
    UTL_FILE.FCLOSE(l_file); -- expect: MIG016 high
  END write_report;

END pkg_pk_a;
/
