create or replace package test_pkg_calc_safe_divide as
  --%suite(Tests for pkg_calc.safe_divide)

  --%test(Divides two positive numbers exactly)
  procedure divide_positive;

  --%test(Returns a fractional result without rounding)
  procedure divide_fractional;

  --%test(Negative dividend gives negative result)
  procedure divide_negative_dividend;

  --%test(Negative divisor gives negative result)
  procedure divide_negative_divisor;

  --%test(Two negatives give a positive result)
  procedure divide_both_negative;

  --%test(Zero dividend with non-zero divisor returns zero)
  procedure zero_dividend;

  --%test(Zero divisor returns NULL)
  procedure zero_divisor_returns_null;

  --%test(NULL divisor returns NULL)
  procedure null_divisor_returns_null;

  --%test(NULL dividend with non-zero divisor returns NULL)
  procedure null_dividend_returns_null;

  --%test(Both NULL returns NULL)
  procedure both_null_returns_null;

  --%test(Zero dividend and zero divisor returns NULL)
  procedure zero_by_zero_returns_null;

  --%test(Divisor of one returns the dividend)
  procedure divisor_one;

  --%test(Dividing a number by itself returns one)
  procedure divide_by_self;

  --%test(Very small divisor gives large result)
  procedure very_small_divisor;

  --%test(Very small non-zero divisor does not raise)
  procedure tiny_divisor_no_error;
end test_pkg_calc_safe_divide;
/
create or replace package body test_pkg_calc_safe_divide as

  procedure divide_positive is
  begin
    ut.expect(pkg_calc.safe_divide(10, 2)).to_equal(5);
  end divide_positive;

  procedure divide_fractional is
  begin
    ut.expect(pkg_calc.safe_divide(1, 4)).to_equal(0.25);
  end divide_fractional;

  procedure divide_negative_dividend is
  begin
    ut.expect(pkg_calc.safe_divide(-9, 3)).to_equal(-3);
  end divide_negative_dividend;

  procedure divide_negative_divisor is
  begin
    ut.expect(pkg_calc.safe_divide(9, -3)).to_equal(-3);
  end divide_negative_divisor;

  procedure divide_both_negative is
  begin
    ut.expect(pkg_calc.safe_divide(-9, -3)).to_equal(3);
  end divide_both_negative;

  procedure zero_dividend is
  begin
    ut.expect(pkg_calc.safe_divide(0, 5)).to_equal(0);
  end zero_dividend;

  procedure zero_divisor_returns_null is
  begin
    ut.expect(pkg_calc.safe_divide(10, 0)).to_be_null();
  end zero_divisor_returns_null;

  procedure null_divisor_returns_null is
  begin
    ut.expect(pkg_calc.safe_divide(10, null)).to_be_null();
  end null_divisor_returns_null;

  procedure null_dividend_returns_null is
  begin
    ut.expect(pkg_calc.safe_divide(null, 5)).to_be_null();
  end null_dividend_returns_null;

  procedure both_null_returns_null is
  begin
    ut.expect(pkg_calc.safe_divide(null, null)).to_be_null();
  end both_null_returns_null;

  procedure zero_by_zero_returns_null is
  begin
    ut.expect(pkg_calc.safe_divide(0, 0)).to_be_null();
  end zero_by_zero_returns_null;

  procedure divisor_one is
  begin
    ut.expect(pkg_calc.safe_divide(42.5, 1)).to_equal(42.5);
  end divisor_one;

  procedure divide_by_self is
  begin
    ut.expect(pkg_calc.safe_divide(7.77, 7.77)).to_equal(1);
  end divide_by_self;

  procedure very_small_divisor is
  begin
    ut.expect(pkg_calc.safe_divide(1, 0.001)).to_equal(1000);
  end very_small_divisor;

  procedure tiny_divisor_no_error is
  begin
    ut.expect(pkg_calc.safe_divide(1, 1e-100)).to_equal(1e100);
  end tiny_divisor_no_error;

end test_pkg_calc_safe_divide;
/
