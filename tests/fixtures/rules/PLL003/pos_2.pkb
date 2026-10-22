-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ledger_post AS

  PROCEDURE retry_posting(p_ledger_id IN NUMBER) IS
    v_tries PLS_INTEGER := 0;
    v_ok    BOOLEAN := FALSE;
  BEGIN
    WHILE NOT v_ok AND v_tries < 3 LOOP
      v_tries := v_tries + 1;
      v_ok := pkg_ledger_api.try_post(p_ledger_id);
      IF NOT v_ok THEN
        ROLLBACK; -- expect: PLL003
      END IF;
    END LOOP;
  END retry_posting;

  PROCEDURE post_all(p_period_id IN NUMBER) IS
    v_n PLS_INTEGER := 0;
  BEGIN
    LOOP
      v_n := v_n + 1;
      pkg_ledger_api.post_next(p_period_id);
      IF MOD(v_n, 100) = 0 THEN
        COMMIT; -- expect: PLL003
      END IF;
      EXIT WHEN pkg_ledger_api.queue_empty(p_period_id);
    END LOOP;
  END post_all;

END pkg_ledger_post;
/
