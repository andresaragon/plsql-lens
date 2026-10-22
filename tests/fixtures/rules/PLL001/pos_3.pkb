-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_price_loader AS

  PROCEDURE load_prices(p_catalog_id IN NUMBER, p_loaded OUT NUMBER) IS
    v_failed BOOLEAN := FALSE;
  BEGIN
    p_loaded := pkg_price_feed.fetch_count(p_catalog_id);
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      v_failed := TRUE;
  END load_prices;

  PROCEDURE load_discounts(p_catalog_id IN NUMBER, p_loaded OUT NUMBER) IS
  BEGIN
    p_loaded := pkg_price_feed.fetch_discounts(p_catalog_id);
  EXCEPTION
    WHEN OTHERS THEN -- expect: PLL001
      p_loaded := 0;
  END load_discounts;

  PROCEDURE reset_catalog(p_catalog_id IN NUMBER) IS
    v_done PLS_INTEGER;
  BEGIN
    pkg_price_feed.clear(p_catalog_id);
    v_done := 1;
  END reset_catalog;

END pkg_price_loader;
/
