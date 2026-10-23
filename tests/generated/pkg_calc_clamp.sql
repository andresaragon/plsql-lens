create or replace package test_pkg_calc_clamp as
  --%suite(Tests for pkg_calc.clamp)

  --%test(Value inside range is returned unchanged)
  procedure value_inside_range;

  --%test(Value below lower bound returns lower bound)
  procedure value_below_lo;

  --%test(Value above upper bound returns upper bound)
  procedure value_above_hi;

  --%test(Value equal to lower bound returns lower bound)
  procedure value_equals_lo;

  --%test(Value equal to upper bound returns upper bound)
  procedure value_equals_hi;

  --%test(Equal bounds return that bound for any value)
  procedure equal_bounds;

  --%test(Negative ranges are handled)
  procedure negative_range;

  --%test(Range spanning zero)
  procedure range_spanning_zero;

  --%test(Decimal values and bounds are handled)
  procedure decimal_values;

  --%test(NULL value returns NULL)
  procedure null_value;

  --%test(NULL lower bound returns NULL)
  procedure null_lo;

  --%test(NULL upper bound returns NULL)
  procedure null_hi;

  --%test(All NULL inputs return NULL)
  procedure all_null;

  --%test(Lower bound greater than upper bound raises ORA-20001)
  --%throws(-20001)
  procedure lo_greater_than_hi_raises;

  --%test(Slightly inverted decimal bounds raise ORA-20001)
  --%throws(-20001)
  procedure lo_slightly_greater_than_hi_raises;

  --%test(Inverted bounds raise ORA-20001 even when value is NULL)
  --%throws(-20001)
  procedure inverted_bounds_with_null_value_raises;
end test_pkg_calc_clamp;
/
create or replace package body test_pkg_calc_clamp as

  procedure value_inside_range is
  begin
    ut.expect(pkg_calc.clamp(5, 1, 10)).to_equal(5);
  end value_inside_range;

  procedure value_below_lo is
  begin
    ut.expect(pkg_calc.clamp(-3, 1, 10)).to_equal(1);
  end value_below_lo;

  procedure value_above_hi is
  begin
    ut.expect(pkg_calc.clamp(99, 1, 10)).to_equal(10);
  end value_above_hi;

  procedure value_equals_lo is
  begin
    ut.expect(pkg_calc.clamp(1, 1, 10)).to_equal(1);
  end value_equals_lo;

  procedure value_equals_hi is
  begin
    ut.expect(pkg_calc.clamp(10, 1, 10)).to_equal(10);
  end value_equals_hi;

  procedure equal_bounds is
  begin
    ut.expect(pkg_calc.clamp(0, 5, 5)).to_equal(5);
    ut.expect(pkg_calc.clamp(5, 5, 5)).to_equal(5);
    ut.expect(pkg_calc.clamp(100, 5, 5)).to_equal(5);
  end equal_bounds;

  procedure negative_range is
  begin
    ut.expect(pkg_calc.clamp(-5, -10, -2)).to_equal(-5);
    ut.expect(pkg_calc.clamp(-20, -10, -2)).to_equal(-10);
    ut.expect(pkg_calc.clamp(0, -10, -2)).to_equal(-2);
  end negative_range;

  procedure range_spanning_zero is
  begin
    ut.expect(pkg_calc.clamp(0, -5, 5)).to_equal(0);
    ut.expect(pkg_calc.clamp(-6, -5, 5)).to_equal(-5);
    ut.expect(pkg_calc.clamp(6, -5, 5)).to_equal(5);
  end range_spanning_zero;

  procedure decimal_values is
  begin
    ut.expect(pkg_calc.clamp(1.25, 0.5, 2.5)).to_equal(1.25);
    ut.expect(pkg_calc.clamp(0.25, 0.5, 2.5)).to_equal(0.5);
    ut.expect(pkg_calc.clamp(2.75, 0.5, 2.5)).to_equal(2.5);
  end decimal_values;

  procedure null_value is
  begin
    ut.expect(pkg_calc.clamp(null, 1, 10)).to_be_null();
  end null_value;

  procedure null_lo is
  begin
    ut.expect(pkg_calc.clamp(5, null, 10)).to_be_null();
  end null_lo;

  procedure null_hi is
  begin
    ut.expect(pkg_calc.clamp(5, 1, null)).to_be_null();
  end null_hi;

  procedure all_null is
  begin
    ut.expect(pkg_calc.clamp(null, null, null)).to_be_null();
  end all_null;

  procedure lo_greater_than_hi_raises is
    l_result number;
  begin
    l_result := pkg_calc.clamp(5, 10, 1);
  end lo_greater_than_hi_raises;

  procedure lo_slightly_greater_than_hi_raises is
    l_result number;
  begin
    l_result := pkg_calc.clamp(1, 1.01, 1);
  end lo_slightly_greater_than_hi_raises;

  procedure inverted_bounds_with_null_value_raises is
    l_result number;
  begin
    l_result := pkg_calc.clamp(null, 10, 1);
  end inverted_bounds_with_null_value_raises;

end test_pkg_calc_clamp;
/
