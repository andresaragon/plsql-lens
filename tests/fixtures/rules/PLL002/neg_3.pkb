-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_audit_purge AS

  PROCEDURE purge_stage(p_cutoff IN DATE) IS
    v_sql VARCHAR2(200) := 'DELETE FROM billing_stage WHERE created_on < :cutoff';
  BEGIN
    EXECUTE IMMEDIATE v_sql USING p_cutoff;
  END purge_stage;

  PROCEDURE purge_with_message(p_cutoff IN DATE, p_note IN VARCHAR2) IS
    v_sql VARCHAR2(200);
    v_msg VARCHAR2(400);
  BEGIN
    v_msg := 'Purging rows older than ' || TO_CHAR(p_cutoff, 'YYYY-MM-DD') || ' (' || p_note || ')';
    DBMS_OUTPUT.PUT_LINE(v_msg);
    v_sql := 'DELETE FROM billing_history WHERE created_on < :cutoff';
    EXECUTE IMMEDIATE v_sql USING p_cutoff;
  END purge_with_message;

  FUNCTION count_stage RETURN NUMBER IS
    v_sql   VARCHAR2(100) := 'SELECT COUNT(*) FROM billing_stage';
    v_count NUMBER;
  BEGIN
    EXECUTE IMMEDIATE v_sql INTO v_count;
    RETURN v_count;
  END count_stage;

END pkg_audit_purge;
/
