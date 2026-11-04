-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_n1 AS

  PROCEDURE similar_names IS
  BEGIN
    dbms_lobby.x;
    dbms_lob_utils.cut(1);
    utl_file_ext.open_it(1);
    dbms_sql2.parse(1);
  END similar_names;

END pkg_pk_n1;
/
