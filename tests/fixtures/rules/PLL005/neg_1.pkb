-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_shipment_batch AS

  TYPE t_id_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

  PROCEDURE close_ready_shipments IS
    l_ids t_id_tab;
  BEGIN
    SELECT shipment_id BULK COLLECT INTO l_ids
      FROM shipments
     WHERE state = 'READY';
    FORALL i IN 1 .. l_ids.COUNT
      UPDATE shipments SET state = 'CLOSED' WHERE shipment_id = l_ids(i);
  END close_ready_shipments;

  PROCEDURE archive_old(p_before IN DATE) IS
    l_ids t_id_tab;
  BEGIN
    SELECT shipment_id BULK COLLECT INTO l_ids
      FROM shipments
     WHERE closed_on < p_before;
    FORALL i IN INDICES OF l_ids
      INSERT INTO shipments_archive SELECT * FROM shipments WHERE shipment_id = l_ids(i);
    FORALL i IN INDICES OF l_ids
      DELETE FROM shipments WHERE shipment_id = l_ids(i);
  END archive_old;

END pkg_shipment_batch;
/
