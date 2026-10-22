-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_order_status AS

  FUNCTION next_status(p_status IN VARCHAR2) RETURN VARCHAR2 IS
    l_next VARCHAR2(20);
  BEGIN
    IF p_status = 'PENDING' THEN -- expect: PLL007
      l_next := 'APPROVED';
    ELSIF p_status = 'APPROVED' THEN
      l_next := 'SHIPPED';
    ELSE
      l_next := p_status;
    END IF;
    RETURN l_next;
  END next_status;

  PROCEDURE reset_order(p_order_id IN NUMBER, p_status OUT VARCHAR2) IS
  BEGIN
    p_status := 'PENDING'; -- expect: PLL007
    UPDATE orders SET status = p_status WHERE order_id = p_order_id;
  END reset_order;

  FUNCTION is_open(p_status IN VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF p_status = 'PENDING' OR p_status = 'SHIPPED' THEN -- expect: PLL007
      RETURN TRUE;
    END IF;
    RETURN FALSE;
  END is_open;

END pkg_order_status;
/
