create or replace package test_pkg_calc_percent_of as
  --%suite(pkg_calc.percent_of unit tests)

  --%test(15 percent of 200 is 30)
  procedure normal_case;

  --%test(Result is rounded to 2 decimals)
  procedure rounds_to_two_decimals;

  --%test(Rounding is half away from zero for positive values)
  procedure rounds_half_up_positive;

  --%test(Rounding is half away from zero for negative values)
  procedure rounds_half_away_negative;

  --%test(Zero percent returns zero)
  procedure zero_pct;

  --%test(Zero value returns zero)
  procedure zero_value;

  --%test(100 percent returns the value)
  procedure hundred_pct;

  --%test(Percent above 100 increases the value)
  procedure pct_above_hundred;

  --%test(Negative percent returns negative result)
  procedure negative_pct;

  --%test(Negative value returns negative result)
  procedure negative_value;

  --%test(Two negatives give positive result)
  procedure both_negative;

  --%test(Fractional percent)
  procedure fractional_pct;

  --%test(Very small result rounds to zero)
  procedure tiny_result_rounds_to_zero;

  --%test(NULL value returns NULL)
  procedure null_value;

  --%test(NULL percent returns NULL)
  procedure null_pct;

  --%test(Both NULL returns NULL)
  procedure both_null;

  --%test(Large values are computed correctly)
  procedure large_values;
end test_pkg_calc_percent_of;
/
create or replace package body test_pkg_calc_percent_of as

  procedure normal_case is
  begin
    ut.expect(pkg_calc.percent_of(200, 15)).to_equal(30);
  end normal_case;

  procedure rounds_to_two_decimals is
  begin
    -- 10 * 33.333 / 100 = 3.3333 -> 3.33
    ut.expect(pkg_calc.percent_of(10, 33.333)).to_equal(3.33);
  end rounds_to_two_decimals;

  procedure rounds_half_up_positive is
  begin
    -- 1 * 0.5 / 100 = 0.005 -> 0.01
    ut.expect(pkg_calc.percent_of(1, 0.5)).to_equal(0.01);
  end rounds_half_up_positive;

  procedure rounds_half_away_negative is
  begin
    -- -1 * 0.5 / 100 = -0.005 -> -0.01
    ut.expect(pkg_calc.percent_of(-1, 0.5)).to_equal(-0.01);
  end rounds_half_away_negative;

  procedure zero_pct is
  begin
    ut.expect(pkg_calc.percent_of(123.45, 0)).to_equal(0);
  end zero_pct;

  procedure zero_value is
  begin
    ut.expect(pkg_calc.percent_of(0, 50)).to_equal(0);
  end zero_value;

  procedure hundred_pct is
  begin
    ut.expect(pkg_calc.percent_of(123.45, 100)).to_equal(123.45);
  end hundred_pct;

  procedure pct_above_hundred is
  begin
    ut.expect(pkg_calc.percent_of(50, 250)).to_equal(125);
  end pct_above_hundred;

  procedure negative_pct is
  begin
    ut.expect(pkg_calc.percent_of(200, -10)).to_equal(-20);
  end negative_pct;

  procedure negative_value is
  begin
    ut.expect(pkg_calc.percent_of(-200, 10)).to_equal(-20);
  end negative_value;

  procedure both_negative is
  begin
    ut.expect(pkg_calc.percent_of(-200, -10)).to_equal(20);
  end both_negative;

  procedure fractional_pct is
  begin
    ut.expect(pkg_calc.percent_of(100, 12.5)).to_equal(12.5);
  end fractional_pct;

  procedure tiny_result_rounds_to_zero is
  begin
    -- 1 * 0.1 / 100 = 0.001 -> 0
    ut.expect(pkg_calc.percent_of(1, 0.1)).to_equal(0);
  end tiny_result_rounds_to_zero;

  procedure null_value is
  begin
    ut.expect(pkg_calc.percent_of(null, 10)).to_be_null();
  end null_value;

  procedure null_pct is
  begin
    ut.expect(pkg_calc.percent_of(100, null)).to_be_null();
  end null_pct;

  procedure both_null is
  begin
    ut.expect(pkg_calc.percent_of(null, null)).to_be_null();
  end both_null;

  procedure large_values is
  begin
    ut.expect(pkg_calc.percent_of(1000000000, 25)).to_equal(250000000);
  end large_values;

end test_pkg_calc_percent_of;
/
