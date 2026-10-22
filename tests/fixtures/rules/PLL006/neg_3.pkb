-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_status_checks AS

  PROCEDURE check_status(p_status IN orders.status%TYPE) IS
    l_id   orders.order_id%TYPE;
    l_name customers.name%TYPE;
    l_made orders.created_on%TYPE;
  BEGIN
    l_id := 42;
    l_name := 'ACME';
    l_made := SYSDATE;
    IF p_status = 10 THEN
      DBMS_OUTPUT.PUT_LINE('status is numeric-looking');
    END IF;
    IF l_id = 'A-1' THEN
      DBMS_OUTPUT.PUT_LINE('id looks like text');
    END IF;
    IF l_name = 99 THEN
      DBMS_OUTPUT.PUT_LINE('name looks like a number');
    END IF;
    IF l_made > '2025-01-01' THEN
      DBMS_OUTPUT.PUT_LINE('made after the cutoff');
    END IF;
  END check_status;

  FUNCTION same_owner(p_a IN customers.name%TYPE, p_b IN customers.name%TYPE) RETURN BOOLEAN IS
  BEGIN
    IF p_a = p_b THEN
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END same_owner;

END pkg_status_checks;
/
