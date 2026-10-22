-- Written for this repo.
CREATE OR REPLACE PROCEDURE review_customer_accounts(p_customer_id IN NUMBER) IS
  l_state   VARCHAR2(20);
  l_idle    NUMBER;
  l_grace   NUMBER;
  l_message VARCHAR2(100);
BEGIN
  l_state := 'ACTIVE'; -- expect: PLL007
  l_grace := 30; -- expect: PLL007
  SELECT MAX(days_idle) INTO l_idle FROM customer_activity WHERE customer_id = p_customer_id;
  IF l_idle > 30 THEN -- expect: PLL007
    l_state := 'DORMANT';
  END IF;
  IF l_idle > l_grace + 30 THEN -- expect: PLL007
    l_state := 'CLOSED';
  END IF;
  IF l_state = 'ACTIVE' THEN -- expect: PLL007
    l_message := 'account ' || p_customer_id || ' is in good standing';
  ELSIF l_state <> 'ACTIVE' THEN -- expect: PLL007
    l_message := 'account ' || p_customer_id || ' needs review';
  END IF;
  UPDATE customers SET state = l_state WHERE customer_id = p_customer_id;
  DBMS_OUTPUT.PUT_LINE(l_message);
END review_customer_accounts;
/
