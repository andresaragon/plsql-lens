-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_stock_reserve AS

  PROCEDURE reserve_stock(p_sku IN VARCHAR2, p_qty IN NUMBER) IS
    v_available NUMBER;
  BEGIN
    BEGIN
      SELECT on_hand -- expect: PLL004
        INTO v_available
        FROM stock_level
       WHERE sku = p_sku;
    EXCEPTION
      WHEN VALUE_ERROR THEN
        v_available := 0;
    END;
    IF v_available >= p_qty THEN
      pkg_stock_store.hold(p_sku, p_qty);
    END IF;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      pkg_stock_store.release(p_sku);
  END reserve_stock;

  PROCEDURE check_threshold(p_sku IN VARCHAR2) IS
    v_limit NUMBER;
  BEGIN
    BEGIN
      SELECT reorder_limit INTO v_limit FROM stock_policy WHERE sku = p_sku; -- expect: PLL004
    EXCEPTION
      WHEN ZERO_DIVIDE THEN
        v_limit := 0;
    END;
    pkg_stock_store.flag_low(p_sku, v_limit);
  END check_threshold;

END pkg_stock_reserve;
/
