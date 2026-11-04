-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_n2 AS

  PROCEDURE qualified IS
  BEGIN
    my_pkg.dbms_lob.substr(1);
    other.utl_file.fopen(1);
    x.sys.dbms_sql.open_cursor;
  END qualified;

END pkg_pk_n2;
/
