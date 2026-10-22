-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_invoice_batch AS

  PROCEDURE settle_invoices(p_run_id IN NUMBER) IS
  BEGIN
    FOR inv IN (SELECT invoice_id FROM invoice WHERE run_id = p_run_id) LOOP
      pkg_invoice_api.settle(inv.invoice_id);
    END LOOP;
    COMMIT;
  END settle_invoices;

  PROCEDURE reopen_run(p_run_id IN NUMBER) IS
    v_n PLS_INTEGER := 0;
  BEGIN
    WHILE v_n < 5 LOOP
      v_n := v_n + 1;
      pkg_invoice_api.reopen_step(p_run_id, v_n);
    END LOOP;
    COMMIT;
  END reopen_run;

  FUNCTION try_close(p_run_id IN NUMBER) RETURN BOOLEAN IS
  BEGIN
    pkg_invoice_api.close_run(p_run_id);
    RETURN TRUE;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      ROLLBACK;
      RETURN FALSE;
  END try_close;

END pkg_invoice_batch;
/
