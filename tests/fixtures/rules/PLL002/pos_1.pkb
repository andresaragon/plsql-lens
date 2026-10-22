-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_stock_maint AS

  PROCEDURE clear_staging(p_table_name IN VARCHAR2, p_batch_id IN NUMBER) IS
  BEGIN
    EXECUTE IMMEDIATE 'DELETE FROM ' || p_table_name || ' WHERE batch_id = :b' USING p_batch_id; -- expect: PLL002
  END clear_staging;

  PROCEDURE rename_bucket(p_old IN VARCHAR2, p_new IN VARCHAR2) IS
  BEGIN
    EXECUTE IMMEDIATE -- expect: PLL002
      'ALTER TABLE stock_bucket RENAME COLUMN ' || p_old || ' TO ' || p_new;
  END rename_bucket;

  FUNCTION bucket_count(p_bucket_id IN NUMBER) RETURN NUMBER IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO v_count
      FROM stock_bucket
     WHERE bucket_id = p_bucket_id;
    RETURN v_count;
  END bucket_count;

  PROCEDURE reset_counter(p_bucket_id IN NUMBER) IS
  BEGIN
    EXECUTE IMMEDIATE 'UPDATE stock_bucket SET moves = 0 WHERE bucket_id = :id'
      USING p_bucket_id;
  END reset_counter;

END pkg_stock_maint;
/
