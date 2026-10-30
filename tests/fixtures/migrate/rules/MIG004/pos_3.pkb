-- Written for this repo.
CREATE OR REPLACE PACKAGE BODY pkg_seq_c AS

  PROCEDURE next_two(p_a OUT NUMBER, p_b OUT NUMBER) IS
  BEGIN
    p_a := app.seq_x.nextval; -- expect: MIG004
    p_b := seq_y
      .nextval; -- expect: MIG004
  END next_two;

END pkg_seq_c;
/
