-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_cleanup AS

  PROCEDURE archive_order(p_order_id IN NUMBER) IS
    v_status VARCHAR2(20) := 'ARCHIVED';
  BEGIN
    pkg_order_store.set_status(p_order_id, v_status);
    pkg_order_store.touch(p_order_id);
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      NULL;
  END archive_order;

  PROCEDURE purge_drafts(p_days IN NUMBER) IS
  BEGIN
    pkg_order_store.delete_drafts(p_days);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END purge_drafts;

  PROCEDURE refresh_totals(p_customer_id IN NUMBER) IS
    v_attempts PLS_INTEGER := 0;
  BEGIN
    v_attempts := v_attempts + 1;
    pkg_order_store.recalc_totals(p_customer_id);
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      NULL;
  END refresh_totals;

END pkg_order_cleanup;
/
