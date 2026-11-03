-- Written for this repo.
CREATE OR REPLACE PACKAGE pkg_pl_a AS

  FUNCTION list_names RETURN t_names PIPELINED; -- expect: MIG017

END pkg_pl_a;
/
