-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ship_dates AS

  FUNCTION to_ship_date(p_text IN VARCHAR2) RETURN DATE IS
  BEGIN
    RETURN TO_DATE(p_text, 'YYYY-MM-DD');
  END to_ship_date;

  FUNCTION to_event_ts(p_text IN VARCHAR2) RETURN TIMESTAMP IS
  BEGIN
    RETURN TO_TIMESTAMP(p_text, 'YYYY-MM-DD HH24:MI:SS');
  END to_event_ts;

  FUNCTION to_due_date(p_text IN VARCHAR2, p_mask IN VARCHAR2) RETURN DATE IS
  BEGIN
    RETURN TO_DATE(p_text, p_mask);
  END to_due_date;

  PROCEDURE stamp_delivery(p_order_id IN NUMBER, p_text IN VARCHAR2) IS
    l_when DATE;
  BEGIN
    l_when := TO_DATE(TRIM(p_text), 'DD/MM/YYYY');
    UPDATE deliveries SET delivered_on = l_when WHERE order_id = p_order_id;
  END stamp_delivery;

  FUNCTION to_short_date(p_text IN VARCHAR2) RETURN DATE IS
  BEGIN
    RETURN TO_DATE(SUBSTR(p_text, 1, 10), 'YYYY-MM-DD');
  END to_short_date;

END pkg_ship_dates;
/
