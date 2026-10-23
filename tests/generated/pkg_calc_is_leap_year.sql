create or replace package test_pkg_calc_is_leap_year as
  --%suite(pkg_calc.is_leap_year tests)

  --%test(Year divisible by 4 but not 100 is a leap year)
  procedure leap_div_by_4;

  --%test(Year not divisible by 4 is not a leap year)
  procedure not_leap_common_year;

  --%test(Century year not divisible by 400 is not a leap year)
  procedure not_leap_century;

  --%test(Year divisible by 400 is a leap year)
  procedure leap_div_by_400;

  --%test(Boundary years around a leap year)
  procedure boundary_neighbors;

  --%test(NULL year returns FALSE)
  procedure null_year_returns_false;

  --%test(Year zero is divisible by 400 and is a leap year)
  procedure year_zero;

  --%test(Negative years follow the same rules)
  procedure negative_years;

  --%test(Result agrees with an independent SQL computation for 1 to 2400)
  procedure matches_independent_sql;
end test_pkg_calc_is_leap_year;
/
create or replace package body test_pkg_calc_is_leap_year as

  procedure leap_div_by_4 is
  begin
    ut.expect(pkg_calc.is_leap_year(2024)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(1996)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(4)).to_be_true();
  end leap_div_by_4;

  procedure not_leap_common_year is
  begin
    ut.expect(pkg_calc.is_leap_year(2023)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(2025)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(1)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(2)).to_be_false();
  end not_leap_common_year;

  procedure not_leap_century is
  begin
    ut.expect(pkg_calc.is_leap_year(1900)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(2100)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(100)).to_be_false();
  end not_leap_century;

  procedure leap_div_by_400 is
  begin
    ut.expect(pkg_calc.is_leap_year(2000)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(1600)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(400)).to_be_true();
  end leap_div_by_400;

  procedure boundary_neighbors is
  begin
    ut.expect(pkg_calc.is_leap_year(1999)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(2000)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(2001)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(1899)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(1900)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(1901)).to_be_false();
  end boundary_neighbors;

  procedure null_year_returns_false is
  begin
    ut.expect(pkg_calc.is_leap_year(null)).to_be_false();
  end null_year_returns_false;

  procedure year_zero is
  begin
    ut.expect(pkg_calc.is_leap_year(0)).to_be_true();
  end year_zero;

  procedure negative_years is
  begin
    ut.expect(pkg_calc.is_leap_year(-4)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(-100)).to_be_false();
    ut.expect(pkg_calc.is_leap_year(-400)).to_be_true();
    ut.expect(pkg_calc.is_leap_year(-3)).to_be_false();
  end negative_years;

  procedure matches_independent_sql is
    l_mismatches pls_integer;
    l_bad        pls_integer := 0;
    l_expected   boolean;
  begin
    for r in (
      select level as yr,
             case
               when mod(level, 400) = 0 then 1
               when mod(level, 100) = 0 then 0
               when mod(level, 4) = 0 then 1
               else 0
             end as is_leap
        from dual
      connect by level <= 2400
    ) loop
      l_expected := (r.is_leap = 1);
      if pkg_calc.is_leap_year(r.yr) <> l_expected then
        l_bad := l_bad + 1;
      end if;
    end loop;
    l_mismatches := l_bad;
    ut.expect(l_mismatches).to_equal(0);
  end matches_independent_sql;

end test_pkg_calc_is_leap_year;
/
