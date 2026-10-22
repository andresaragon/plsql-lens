-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_inventory_sync AS

  PROCEDURE sync_warehouses IS
  BEGIN
    FOR w IN (SELECT warehouse_id FROM warehouse WHERE active_flag = 'Y') LOOP
      pkg_inventory_store.recount(w.warehouse_id);
      COMMIT; -- expect: PLL003
    END LOOP;
  END sync_warehouses;

  PROCEDURE finalize_sync IS
  BEGIN
    pkg_inventory_store.close_period;
    COMMIT;
  END finalize_sync;

  PROCEDURE rebuild_slots(p_rounds IN NUMBER) IS
  BEGIN
    FOR i IN 1 .. p_rounds LOOP
      pkg_inventory_store.rebuild_slot(i);
      COMMIT; -- expect: PLL003
    END LOOP;
  END rebuild_slots;

END pkg_inventory_sync;
/
