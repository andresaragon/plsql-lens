-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_warehouse_ddl AS

  PROCEDURE truncate_stage(p_table IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || DBMS_ASSERT.SQL_OBJECT_NAME(p_table);
  END truncate_stage;

  PROCEDURE build_index IS
  BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_' || 'orders' || '_cust ON orders (customer_id)';
  END build_index;

  PROCEDURE open_view(p_view IN VARCHAR2, p_rc OUT SYS_REFCURSOR) IS
  BEGIN
    OPEN p_rc FOR 'SELECT * FROM ' || DBMS_ASSERT.ENQUOTE_NAME(p_view, FALSE)
      || ' WHERE ROWNUM < 25';
  END open_view;

  PROCEDURE drop_old(p_schema IN VARCHAR2, p_table IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || DBMS_ASSERT.ENQUOTE_NAME(p_schema) || '.'
      || DBMS_ASSERT.ENQUOTE_NAME(p_table) || ' PURGE';
  END drop_old;

END pkg_warehouse_ddl;
/
