-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_n2 AS

  PROCEDURE flags(p_row IN t_row) IS
    bulk_size NUMBER := 100;
    l_bulk    NUMBER;
    collect_count NUMBER := 0;
  BEGIN
    l_bulk := p_row.bulk;
    bulk_size := p_row.bulk + collect_count;
    bulk_collect := 1;
  END flags;

END pkg_bc_n2;
/
