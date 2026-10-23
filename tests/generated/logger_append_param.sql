create or replace package test_logger_append_param
as
  --%suite(Tests for logger.append_param overloads)

  --%test(varchar2: appends one param to an empty table)
  procedure varchar2_empty_table;

  --%test(varchar2: appends at count+1 and keeps order)
  procedure varchar2_multiple_order;

  --%test(varchar2: existing entries are preserved)
  procedure varchar2_preserves_existing;

  --%test(varchar2: null value is stored as null)
  procedure varchar2_null_val;

  --%test(varchar2: null name is stored as null)
  procedure varchar2_null_name;

  --%test(varchar2: name of 255 chars and value of 4000 chars accepted)
  procedure varchar2_max_lengths;

  --%test(varchar2: name longer than 255 raises value error)
  --%throws(-6502)
  procedure varchar2_name_too_long;

  --%test(varchar2: value longer than 4000 raises value error)
  --%throws(-6502)
  procedure varchar2_val_too_long;

  --%test(number: value converted with tochar)
  procedure number_val;

  --%test(number: null value)
  procedure number_null;

  --%test(date: value converted with tochar)
  procedure date_val;

  --%test(date: null value)
  procedure date_null;

  --%test(timestamp: value converted with tochar)
  procedure timestamp_val;

  --%test(timestamp: null value)
  procedure timestamp_null;

  --%test(timestamp with time zone: value converted with tochar)
  procedure timestamp_tz_val;

  --%test(timestamp with time zone: null value)
  procedure timestamp_tz_null;

  --%test(timestamp with local time zone: value converted with tochar)
  procedure timestamp_ltz_val;

  --%test(timestamp with local time zone: null value)
  procedure timestamp_ltz_null;

  --%test(boolean: true value)
  procedure boolean_true;

  --%test(boolean: false value)
  procedure boolean_false;

  --%test(boolean: null value)
  procedure boolean_null;

  --%test(mixed overloads append sequentially)
  procedure mixed_overloads;
end test_logger_append_param;
/
create or replace package body test_logger_append_param
as
  procedure varchar2_empty_table
  as
    l_params logger.tab_param;
  begin
    logger.append_param(l_params, 'NAME1', 'VALUE1');
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('NAME1');
    ut.expect(l_params(1).val).to_equal('VALUE1');
  end;

  procedure varchar2_multiple_order
  as
    l_params logger.tab_param;
  begin
    logger.append_param(l_params, 'A', 'one');
    logger.append_param(l_params, 'B', 'two');
    logger.append_param(l_params, 'C', 'three');
    ut.expect(l_params.count).to_equal(3);
    ut.expect(l_params(1).name).to_equal('A');
    ut.expect(l_params(2).name).to_equal('B');
    ut.expect(l_params(3).name).to_equal('C');
    ut.expect(l_params(3).val).to_equal('three');
  end;

  procedure varchar2_preserves_existing
  as
    l_params logger.tab_param;
  begin
    l_params(1).name := 'PRE';
    l_params(1).val := 'EXISTING';
    logger.append_param(l_params, 'NEW', 'ADDED');
    ut.expect(l_params.count).to_equal(2);
    ut.expect(l_params(1).name).to_equal('PRE');
    ut.expect(l_params(1).val).to_equal('EXISTING');
    ut.expect(l_params(2).name).to_equal('NEW');
    ut.expect(l_params(2).val).to_equal('ADDED');
  end;

  procedure varchar2_null_val
  as
    l_params logger.tab_param;
    l_val    varchar2(10) := null;
  begin
    logger.append_param(l_params, 'N', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('N');
    ut.expect(l_params(1).val).to_be_null();
  end;

  procedure varchar2_null_name
  as
    l_params logger.tab_param;
    l_name   varchar2(10) := null;
  begin
    logger.append_param(l_params, l_name, 'V');
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_be_null();
    ut.expect(l_params(1).val).to_equal('V');
  end;

  procedure varchar2_max_lengths
  as
    l_params logger.tab_param;
    l_name   varchar2(255) := rpad('n', 255, 'n');
    l_val    varchar2(4000) := rpad('v', 4000, 'v');
  begin
    logger.append_param(l_params, l_name, l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(length(l_params(1).name)).to_equal(255);
    ut.expect(length(l_params(1).val)).to_equal(4000);
    ut.expect(l_params(1).name).to_equal(l_name);
    ut.expect(l_params(1).val).to_equal(l_val);
  end;

  procedure varchar2_name_too_long
  as
    l_params logger.tab_param;
    l_name   varchar2(300) := rpad('n', 256, 'n');
  begin
    logger.append_param(l_params, l_name, 'V');
  end;

  procedure varchar2_val_too_long
  as
    l_params logger.tab_param;
    l_val    varchar2(5000) := rpad('v', 4001, 'v');
  begin
    logger.append_param(l_params, 'N', l_val);
  end;

  procedure number_val
  as
    l_params logger.tab_param;
    l_val    number := 12345.678;
  begin
    logger.append_param(l_params, 'NUM', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('NUM');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure number_null
  as
    l_params logger.tab_param;
    l_val    number := null;
  begin
    logger.append_param(l_params, 'NUM', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('NUM');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure date_val
  as
    l_params logger.tab_param;
    l_val    date := to_date('2020-02-29 13:45:10', 'YYYY-MM-DD HH24:MI:SS');
  begin
    logger.append_param(l_params, 'DT', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('DT');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure date_null
  as
    l_params logger.tab_param;
    l_val    date := null;
  begin
    logger.append_param(l_params, 'DT', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_val
  as
    l_params logger.tab_param;
    l_val    timestamp := to_timestamp('2021-03-04 05:06:07.123456', 'YYYY-MM-DD HH24:MI:SS.FF6');
  begin
    logger.append_param(l_params, 'TS', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('TS');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_null
  as
    l_params logger.tab_param;
    l_val    timestamp := null;
  begin
    logger.append_param(l_params, 'TS', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_tz_val
  as
    l_params logger.tab_param;
    l_val    timestamp with time zone :=
      to_timestamp_tz('2021-03-04 05:06:07.123456 +02:00', 'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM');
  begin
    logger.append_param(l_params, 'TSTZ', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('TSTZ');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_tz_null
  as
    l_params logger.tab_param;
    l_val    timestamp with time zone := null;
  begin
    logger.append_param(l_params, 'TSTZ', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_ltz_val
  as
    l_params logger.tab_param;
    l_val    timestamp with local time zone := to_timestamp('2022-01-02 03:04:05.5', 'YYYY-MM-DD HH24:MI:SS.FF');
  begin
    logger.append_param(l_params, 'TSLTZ', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('TSLTZ');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure timestamp_ltz_null
  as
    l_params logger.tab_param;
    l_val    timestamp with local time zone := null;
  begin
    logger.append_param(l_params, 'TSLTZ', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure boolean_true
  as
    l_params logger.tab_param;
    l_val    boolean := true;
  begin
    logger.append_param(l_params, 'B', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).name).to_equal('B');
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure boolean_false
  as
    l_params logger.tab_param;
    l_val    boolean := false;
  begin
    logger.append_param(l_params, 'B', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
    ut.expect(l_params(1).val = logger.tochar(true)).to_be_false();
  end;

  procedure boolean_null
  as
    l_params logger.tab_param;
    l_val    boolean := null;
  begin
    logger.append_param(l_params, 'B', l_val);
    ut.expect(l_params.count).to_equal(1);
    ut.expect(l_params(1).val).to_equal(logger.tochar(l_val));
  end;

  procedure mixed_overloads
  as
    l_params logger.tab_param;
    l_num    number := 42;
    l_date   date := to_date('2019-12-31', 'YYYY-MM-DD');
    l_bool   boolean := true;
  begin
    logger.append_param(l_params, 'S', 'text');
    logger.append_param(l_params, 'N', l_num);
    logger.append_param(l_params, 'D', l_date);
    logger.append_param(l_params, 'B', l_bool);
    ut.expect(l_params.count).to_equal(4);
    ut.expect(l_params(1).val).to_equal('text');
    ut.expect(l_params(2).val).to_equal(logger.tochar(l_num));
    ut.expect(l_params(3).val).to_equal(logger.tochar(l_date));
    ut.expect(l_params(4).val).to_equal(logger.tochar(l_bool));
    ut.expect(l_params(4).name).to_equal('B');
  end;
end test_logger_append_param;
/
