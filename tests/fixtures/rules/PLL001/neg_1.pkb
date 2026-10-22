-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_shipping_flow AS

  PROCEDURE ship_order(p_order_id IN NUMBER) IS
  BEGIN
    pkg_shipping_api.dispatch(p_order_id);
  EXCEPTION
    WHEN OTHERS THEN
      logger.log_error('ship_order failed for order ' || p_order_id);
      RAISE;
  END ship_order;

  PROCEDURE cancel_shipment(p_order_id IN NUMBER) IS
  BEGIN
    pkg_shipping_api.cancel(p_order_id);
  EXCEPTION
    WHEN OTHERS THEN
      audit_trail.record_failure('cancel_shipment', p_order_id);
  END cancel_shipment;

  PROCEDURE track_shipment(p_order_id IN NUMBER) IS
  BEGIN
    pkg_shipping_api.poll(p_order_id);
  EXCEPTION
    WHEN OTHERS THEN
      trace_util.emit('track_shipment', p_order_id);
  END track_shipment;

END pkg_shipping_flow;
/
