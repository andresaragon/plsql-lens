-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_inventory_sync AS

  PROCEDURE queue_reorders IS
    CURSOR c_low_stock IS
      SELECT item_id, qty_on_hand
        FROM inventory
       WHERE qty_on_hand < reorder_level;
  BEGIN
    FOR r IN c_low_stock LOOP
      INSERT INTO reorder_queue (item_id, requested_on) VALUES (r.item_id, SYSDATE); -- expect: PLL005
    END LOOP;
  END queue_reorders;

  PROCEDURE retire_discontinued(p_cutoff IN DATE) IS
    CURSOR c_old IS
      SELECT item_id FROM inventory WHERE last_sold_on < p_cutoff;
  BEGIN
    FOR rec IN c_old LOOP
      DELETE FROM inventory_notes WHERE item_id = rec.item_id; -- expect: PLL005
      UPDATE inventory SET active_flag = 'X' WHERE item_id = rec.item_id; -- expect: PLL005
    END LOOP;
  END retire_discontinued;

  FUNCTION low_stock_total RETURN NUMBER IS
    l_total NUMBER;
  BEGIN
    SELECT COUNT(*) INTO l_total FROM inventory WHERE qty_on_hand < reorder_level;
    RETURN l_total;
  END low_stock_total;

END pkg_inventory_sync;
/
