create or replace package test_logger_tochar as
  --%suite(logger.tochar overloads)

  --%test(number: integer value)
  procedure number_integer;

  --%test(number: decimal value matches to_char)
  procedure number_decimal;

  --%test(number: negative value)
  procedure number_negative;

  --%test(number: zero)
  procedure number_zero;

  --%test(number: null returns null)
  procedure number_null;

  --%test(date: contains date and time parts)
  procedure date_value;

  --%test(date: midnight boundary keeps time part)
  procedure date_midnight;

  --%test(date: null returns null)
  procedure date_null;

  --%test(timestamp: contains date, time and fractional seconds)
  procedure timestamp_value;

  --%test(timestamp: null returns null)
  procedure timestamp_null;

  --%test(timestamp with time zone: contains time and zone)
  procedure timestamp_tz_value;

  --%test(timestamp with time zone: null returns null)
  procedure timestamp_tz_null;

  --%test(timestamp with local time zone: contains time part)
  procedure timestamp_ltz_value;

  --%test(timestamp with local time zone: null returns null)
  procedure timestamp_ltz_null;

  --%test(boolean: true returns TRUE)
  procedure boolean_true;

  --%test(boolean: false returns FALSE)
  procedure boolean_false;

  --%test(boolean: null returns null)
  procedure boolean_null;
end test_logger_tochar;
/
create or replace package body test_logger_tochar as

  procedure number_integer is
    l_val number := 12345;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_equal('12345');
  end;

  procedure number_decimal is
    l_val number := 123.45;
    l_res varchar2(4000);
    l_exp varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    select to_char(123.45) into l_exp from dual;
    ut.expect(l_res).to_equal(l_exp);
  end;

  procedure number_negative is
    l_val number := -987;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_equal('-987');
  end;

  procedure number_zero is
    l_val number := 0;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_equal('0');
  end;

  procedure number_null is
    l_val number := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

  procedure date_value is
    l_val date := to_date('2024-03-05 13:45:30', 'YYYY-MM-DD HH24:MI:SS');
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_like('%2024%');
    ut.expect(l_res).to_be_like('%13:45:30%');
  end;

  procedure date_midnight is
    l_val date := to_date('2024-12-31 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_like('%2024%');
    ut.expect(l_res).to_be_like('%00:00:00%');
  end;

  procedure date_null is
    l_val date := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

  procedure timestamp_value is
    l_val timestamp := to_timestamp('2024-03-05 13:45:30.123456', 'YYYY-MM-DD HH24:MI:SS.FF');
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_like('%2024%');
    ut.expect(l_res).to_be_like('%13:45:30%');
    ut.expect(l_res).to_be_like('%123456%');
  end;

  procedure timestamp_null is
    l_val timestamp := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

  procedure timestamp_tz_value is
    l_val timestamp with time zone :=
      to_timestamp_tz('2024-03-05 13:45:30.5 +02:00', 'YYYY-MM-DD HH24:MI:SS.FF TZH:TZM');
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_like('%2024%');
    ut.expect(l_res).to_be_like('%13:45:30%');
    ut.expect(l_res).to_be_like('%+02:00%');
  end;

  procedure timestamp_tz_null is
    l_val timestamp with time zone := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

  procedure timestamp_ltz_value is
    l_val timestamp with local time zone := to_timestamp('2024-03-05 13:45:30.25', 'YYYY-MM-DD HH24:MI:SS.FF');
    l_res varchar2(4000);
    l_time varchar2(20);
  begin
    l_res := logger.tochar(l_val);
    l_time := to_char(l_val, 'HH24:MI:SS');
    ut.expect(l_res).to_be_not_null();
    ut.expect(l_res).to_be_like('%' || l_time || '%');
    ut.expect(l_res).to_be_like('%2024%');
  end;

  procedure timestamp_ltz_null is
    l_val timestamp with local time zone := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

  procedure boolean_true is
    l_val boolean := true;
  begin
    ut.expect(logger.tochar(l_val)).to_equal('TRUE');
  end;

  procedure boolean_false is
    l_val boolean := false;
  begin
    ut.expect(logger.tochar(l_val)).to_equal('FALSE');
  end;

  procedure boolean_null is
    l_val boolean := null;
    l_res varchar2(4000);
  begin
    l_res := logger.tochar(l_val);
    ut.expect(l_res).to_be_null();
  end;

end test_logger_tochar;
/
