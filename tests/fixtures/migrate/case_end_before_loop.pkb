CREATE OR REPLACE PACKAGE BODY pkg_min AS

  FUNCTION first_fn(p IN BOOLEAN) RETURN NUMBER IS
    n NUMBER := 0;
  BEGIN
    FOR i IN 1 .. CASE WHEN p THEN 8 ELSE 7 END
    LOOP
      n := n + i;
    END LOOP;
    RETURN n;
  END first_fn;

  FUNCTION second_fn RETURN DATE IS
  BEGIN
    RETURN SYSDATE;
  END second_fn;

END pkg_min;
/
