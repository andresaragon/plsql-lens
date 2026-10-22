-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_billing_push AS

  PROCEDURE push_batches(p_count IN NUMBER) IS
    PROCEDURE flush_batch(p_no IN NUMBER) IS
    BEGIN
      pkg_billing_api.post_batch(p_no);
      COMMIT;
    END flush_batch;
  BEGIN
    FOR i IN 1 .. p_count LOOP
      flush_batch(i);
    END LOOP;
  END push_batches;

  PROCEDURE push_one(p_no IN NUMBER) IS
  BEGIN
    pkg_billing_api.post_batch(p_no);
    COMMIT;
  EXCEPTION
    WHEN VALUE_ERROR THEN
      ROLLBACK;
  END push_one;

  PROCEDURE push_pending IS
    CURSOR c_pending IS SELECT batch_no FROM billing_batch WHERE state_code = 'P';
  BEGIN
    FOR b IN c_pending LOOP
      pkg_billing_api.post_batch(b.batch_no);
    END LOOP;
    COMMIT;
  END push_pending;

END pkg_billing_push;
/
