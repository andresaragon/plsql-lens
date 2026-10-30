-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_n1 AS

  PROCEDURE add_order(p_name IN VARCHAR2) IS
  BEGIN
    INSERT INTO orders (id, name) VALUES (nextval('seq_orders'), p_name);
  END add_order;

END pkg_seq_n1;
/
