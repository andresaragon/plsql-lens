-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_a AS

  PROCEDURE add_order(p_name IN VARCHAR2) IS
  BEGIN
    INSERT INTO orders (id, name)
    VALUES (seq_orders.NEXTVAL, p_name); -- expect: MIG004
  END add_order;

END pkg_seq_a;
/
