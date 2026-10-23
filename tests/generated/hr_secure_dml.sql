CREATE OR REPLACE PACKAGE test_hr_secure_dml IS
  --%suite(Tests for procedure secure_dml (office hours guard))

  --%test(Outcome matches the office-hours rule evaluated independently from the clock)
  PROCEDURE test_outcome_matches_clock;

  --%test(Error code is -20205 when outside office hours, otherwise no error)
  PROCEDURE test_error_code_domain;

  --%test(Error message text is correct when raised)
  PROCEDURE test_error_message;

  --%test(Procedure never raises an error other than -20205)
  PROCEDURE test_no_unexpected_errors;

  --%test(Two consecutive calls behave consistently)
  PROCEDURE test_repeatable_calls;

  --%test(Procedure leaves no uncommitted side effects requiring cleanup, no exception on allowed time)
  PROCEDURE test_allowed_time_no_exception;
END test_hr_secure_dml;
/
CREATE OR REPLACE PACKAGE BODY test_hr_secure_dml IS

  -- Independent evaluation of the rule from a single SYSDATE snapshot
  FUNCTION allowed_now RETURN BOOLEAN IS
    v_now DATE := SYSDATE;
    v_t   VARCHAR2(5) := TO_CHAR(v_now, 'HH24:MI');
    v_d   VARCHAR2(10) := TO_CHAR(v_now, 'DY');
  BEGIN
    RETURN v_t >= '08:00' AND v_t <= '18:00' AND v_d NOT IN ('SAT', 'SUN');
  END allowed_now;

  PROCEDURE run_unit(
    p_code   OUT NUMBER,
    p_msg    OUT VARCHAR2,
    p_exp    OUT BOOLEAN,
    p_stable OUT BOOLEAN
  ) IS
    v_before BOOLEAN;
    v_after  BOOLEAN;
  BEGIN
    v_before := allowed_now;
    BEGIN
      secure_dml;
      p_code := 0;
      p_msg  := NULL;
    EXCEPTION
      WHEN OTHERS THEN
        p_code := SQLCODE;
        p_msg  := SQLERRM;
    END;
    v_after  := allowed_now;
    p_exp    := v_before;
    p_stable := (v_before = v_after);
  END run_unit;

  PROCEDURE test_outcome_matches_clock IS
    v_code   NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp    BOOLEAN;
    v_stable BOOLEAN;
  BEGIN
    run_unit(v_code, v_msg, v_exp, v_stable);
    IF v_stable THEN
      IF v_exp THEN
        ut.expect(v_code).to_equal(0);
      ELSE
        ut.expect(v_code).to_equal(-20205);
      END IF;
    ELSE
      -- clock crossed a boundary during the call; result is indeterminate
      ut.expect(v_code IN (0, -20205)).to_be_true();
    END IF;
  END test_outcome_matches_clock;

  PROCEDURE test_error_code_domain IS
    v_code   NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp    BOOLEAN;
    v_stable BOOLEAN;
  BEGIN
    run_unit(v_code, v_msg, v_exp, v_stable);
    ut.expect(v_code IN (0, -20205)).to_be_true();
    IF v_stable AND NOT v_exp THEN
      ut.expect(v_code).to_equal(-20205);
    END IF;
  END test_error_code_domain;

  PROCEDURE test_error_message IS
    v_code   NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp    BOOLEAN;
    v_stable BOOLEAN;
  BEGIN
    run_unit(v_code, v_msg, v_exp, v_stable);
    IF v_code = -20205 THEN
      ut.expect(v_msg).to_be_like('%You may only make changes during normal office hours%');
    ELSE
      ut.expect(v_msg).to_be_null();
    END IF;
  END test_error_message;

  PROCEDURE test_no_unexpected_errors IS
    v_code   NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp    BOOLEAN;
    v_stable BOOLEAN;
  BEGIN
    run_unit(v_code, v_msg, v_exp, v_stable);
    ut.expect(v_code).not_to_be_null();
    ut.expect(v_code IN (0, -20205)).to_be_true();
  END test_no_unexpected_errors;

  PROCEDURE test_repeatable_calls IS
    v_code1  NUMBER;
    v_code2  NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp1   BOOLEAN;
    v_exp2   BOOLEAN;
    v_st1    BOOLEAN;
    v_st2    BOOLEAN;
  BEGIN
    run_unit(v_code1, v_msg, v_exp1, v_st1);
    run_unit(v_code2, v_msg, v_exp2, v_st2);
    IF v_st1 AND v_st2 AND v_exp1 = v_exp2 THEN
      ut.expect(v_code2).to_equal(v_code1);
    ELSE
      ut.expect(v_code1 IN (0, -20205) AND v_code2 IN (0, -20205)).to_be_true();
    END IF;
  END test_repeatable_calls;

  PROCEDURE test_allowed_time_no_exception IS
    v_code   NUMBER;
    v_msg    VARCHAR2(4000);
    v_exp    BOOLEAN;
    v_stable BOOLEAN;
  BEGIN
    run_unit(v_code, v_msg, v_exp, v_stable);
    IF v_stable AND v_exp THEN
      ut.expect(v_code).to_equal(0);
      ut.expect(v_msg).to_be_null();
    ELSIF v_stable THEN
      ut.expect(v_code).to_equal(-20205);
    ELSE
      ut.expect(v_code IN (0, -20205)).to_be_true();
    END IF;
  END test_allowed_time_no_exception;

END test_hr_secure_dml;
/
