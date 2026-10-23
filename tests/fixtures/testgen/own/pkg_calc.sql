-- Written for this repo. Pure numeric helpers.
create or replace package pkg_calc as
  -- Rounds to 2 decimals, half away from zero. NULL in, NULL out.
  function round_money(p_amount number) return number;
  -- p_pct percent of p_value (p_pct = 15 means 15 %), rounded to 2 decimals. NULL if either is NULL.
  function percent_of(p_value number, p_pct number) return number;
  -- Division that returns NULL instead of raising when the divisor is 0 or NULL.
  function safe_divide(p_a number, p_b number) return number;
  -- Limits p_value to [p_lo, p_hi]. Raises ORA-20001 when p_lo > p_hi. NULL value stays NULL.
  function clamp(p_value number, p_lo number, p_hi number) return number;
  -- Gregorian leap year test. NULL year returns FALSE.
  function is_leap_year(p_year pls_integer) return boolean;
end pkg_calc;
/
create or replace package body pkg_calc as
  function round_money(p_amount number) return number is
  begin
    return round(p_amount, 2);
  end round_money;

  function percent_of(p_value number, p_pct number) return number is
  begin
    if p_value is null or p_pct is null then
      return null;
    end if;
    return round(p_value * p_pct / 100, 2);
  end percent_of;

  function safe_divide(p_a number, p_b number) return number is
  begin
    if p_b is null or p_b = 0 then
      return null;
    end if;
    return p_a / p_b;
  end safe_divide;

  function clamp(p_value number, p_lo number, p_hi number) return number is
  begin
    if p_lo > p_hi then
      raise_application_error(-20001, 'lower bound greater than upper bound');
    end if;
    return greatest(p_lo, least(p_hi, p_value));
  end clamp;

  function is_leap_year(p_year pls_integer) return boolean is
  begin
    if p_year is null then
      return false;
    end if;
    return (mod(p_year, 4) = 0 and mod(p_year, 100) <> 0) or mod(p_year, 400) = 0;
  end is_leap_year;
end pkg_calc;
/
