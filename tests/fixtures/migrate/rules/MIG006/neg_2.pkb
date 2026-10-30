-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_cb_n2 AS

  PROCEDURE grants IS
  BEGIN
    EXECUTE IMMEDIATE 'GRANT CONNECT TO app_user';
    FOR r IN (SELECT CONNECT_BY_ROOT id AS root_id FROM nodes) LOOP
      NULL;
    END LOOP;
  END grants;

END pkg_cb_n2;
/
