-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_pk_c AS

  FUNCTION head(p_doc IN CLOB) RETURN VARCHAR2 IS
    l_len INTEGER;
  BEGIN
    l_len := DBMS_LOB.GETLENGTH(p_doc); -- expect: MIG016 medium
    RETURN dbms_lob.substr(p_doc, 100, 1); -- expect: MIG016 medium
  END head;

  PROCEDURE add_text(p_doc IN OUT NOCOPY CLOB, p_text IN VARCHAR2) IS
  BEGIN
    sys.dbms_lob.writeappend(p_doc, LENGTH(p_text), p_text); -- expect: MIG016 medium
  END add_text;

  PROCEDURE open_it(p_doc IN OUT NOCOPY CLOB) IS
  BEGIN
    dbms_lob.open(p_doc, dbms_lob.lob_readwrite); -- expect: MIG016 medium
  END open_it;

END pkg_pk_c;
/
