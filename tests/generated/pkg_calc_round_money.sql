create or replace package test_pkg_calc_round_money as
  --%suite(pkg_calc.round_money tests)

  --%test(Rounds down when third decimal is below 5)
  procedure rounds_down;

  --%test(Rounds up when third decimal is above 5)
  procedure rounds_up;

  --%test(Half rounds away from zero for positive)
  procedure half_positive;

  --%test(Half rounds away from zero for negative)
  procedure half_negative;

  --%test(Negative value rounds correctly)
  procedure negative_value;

  --%test(Value with two decimals is unchanged)
  procedure unchanged_two_decimals;

  --%test(Integer is unchanged)
  procedure integer_unchanged;

  --%test(Zero returns zero)
  procedure zero_value;

  --%test(Tiny value rounds to zero)
  procedure tiny_value;

  --%test(Value just below half cent rounds down)
  procedure just_below_half;

  --%test(Large value rounds correctly)
  procedure large_value;

  --%test(NULL input returns NULL)
  procedure null_input;
end test_pkg_calc_round_money;
/
create or replace package body test_pkg_calc_round_money as

  procedure rounds_down is
  begin
    ut.expect(pkg_calc.round_money(1.234)).to_equal(1.23);
  end rounds_down;

  procedure rounds_up is
  begin
    ut.expect(pkg_calc.round_money(1.236)).to_equal(1.24);
  end rounds_up;

  procedure half_positive is
  begin
    ut.expect(pkg_calc.round_money(2.005)).to_equal(2.01);
    ut.expect(pkg_calc.round_money(0.125)).to_equal(0.13);
  end half_positive;

  procedure half_negative is
  begin
    ut.expect(pkg_calc.round_money(-2.005)).to_equal(-2.01);
    ut.expect(pkg_calc.round_money(-0.125)).to_equal(-0.13);
  end half_negative;

  procedure negative_value is
  begin
    ut.expect(pkg_calc.round_money(-3.456)).to_equal(-3.46);
    ut.expect(pkg_calc.round_money(-3.454)).to_equal(-3.45);
  end negative_value;

  procedure unchanged_two_decimals is
  begin
    ut.expect(pkg_calc.round_money(12.34)).to_equal(12.34);
  end unchanged_two_decimals;

  procedure integer_unchanged is
  begin
    ut.expect(pkg_calc.round_money(100)).to_equal(100);
  end integer_unchanged;

  procedure zero_value is
  begin
    ut.expect(pkg_calc.round_money(0)).to_equal(0);
  end zero_value;

  procedure tiny_value is
  begin
    ut.expect(pkg_calc.round_money(0.004)).to_equal(0);
    ut.expect(pkg_calc.round_money(-0.004)).to_equal(0);
  end tiny_value;

  procedure just_below_half is
  begin
    ut.expect(pkg_calc.round_money(0.0049999)).to_equal(0);
    ut.expect(pkg_calc.round_money(0.005)).to_equal(0.01);
  end just_below_half;

  procedure large_value is
  begin
    ut.expect(pkg_calc.round_money(123456789012.345)).to_equal(123456789012.35);
  end large_value;

  procedure null_input is
  begin
    ut.expect(pkg_calc.round_money(null)).to_be_null();
  end null_input;

end test_pkg_calc_round_money;
/
