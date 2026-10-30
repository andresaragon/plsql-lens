-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_n3 AS

  PROCEDURE note IS
    v_sql VARCHAR2(100) := 'select seq_orders.nextval from dual';
  BEGIN
    -- seq_orders.NEXTVAL moves to nextval('seq_orders')
    /* a.b.currval */
    NULL;
  END note;

END pkg_seq_n3;
/
