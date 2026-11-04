-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_bc_b AS

  PROCEDURE drain(p_cur IN SYS_REFCURSOR) IS
    TYPE t_names IS TABLE OF VARCHAR2(100);
    l_names t_names;
  BEGIN
    LOOP
      FETCH p_cur
        BULK -- expect: MIG012
        COLLECT INTO l_names LIMIT 100;
      EXIT WHEN l_names.COUNT = 0;
    END LOOP;
  END drain;

END pkg_bc_b;
/
