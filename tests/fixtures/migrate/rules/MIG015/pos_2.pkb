-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_ra_b AS

  PROCEDURE fail_loud IS
  BEGIN
    do_work;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      raise_application_error (-20002, 'missing', TRUE); -- expect: MIG015
    WHEN OTHERS THEN
      IF SQLCODE = -20003 THEN
        NULL;
      END IF;
      Raise_Application_Error( -- expect: MIG015
        -20004,
        'other');
  END fail_loud;

END pkg_ra_b;
/
