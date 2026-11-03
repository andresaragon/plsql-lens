-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_n3 AS

  PROCEDURE note IS
    l_text VARCHAR2(100) := 'UTL_FILE.FOPEN and DBMS_LOB.GETLENGTH';
    dbms_sql_count NUMBER := 0;
  BEGIN
    -- DBMS_SQL.OPEN_CURSOR was replaced
    /* utl_file.fopen(a, b, 'w') */
    dbms_sql_count := dbms_sql_count + 1;
    EXECUTE_IT('GRANT EXECUTE ON dbms_lob TO app_user');
  END note;

END pkg_pk_n3;
/
