-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_customer_sync AS

  e_stale_record EXCEPTION;

  FUNCTION find_email(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
  BEGIN
    RETURN pkg_customer_store.email_of(p_customer_id);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
      RETURN 'DUPLICATE';
  END find_email;

  PROCEDURE push_customer(p_customer_id IN NUMBER) IS
  BEGIN
    pkg_customer_store.push(p_customer_id);
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      NULL;
    WHEN e_stale_record THEN
      pkg_customer_store.refresh(p_customer_id);
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20010, 'Customer push failed: ' || p_customer_id);
  END push_customer;

  PROCEDURE check_customer(p_customer_id IN NUMBER) IS
  BEGIN
    IF pkg_customer_store.is_stale(p_customer_id) THEN
      RAISE e_stale_record;
    END IF;
  EXCEPTION
    WHEN e_stale_record THEN
      pkg_customer_store.refresh(p_customer_id);
  END check_customer;

END pkg_customer_sync;
/
