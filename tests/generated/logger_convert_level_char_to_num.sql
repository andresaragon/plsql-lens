create or replace package test_logger_convert_level_char_to_num as

  --%suite(logger.convert_level_char_to_num)

  --%test(OFF maps to g_off)
  procedure off_level;

  --%test(PERMANENT maps to g_permanent)
  procedure permanent_level;

  --%test(ERROR maps to g_error)
  procedure error_level;

  --%test(WARNING maps to g_warning)
  procedure warning_level;

  --%test(INFORMATION maps to g_information)
  procedure information_level;

  --%test(DEBUG maps to g_debug)
  procedure debug_level;

  --%test(TIMING maps to g_timing)
  procedure timing_level;

  --%test(SYS_CONTEXT maps to g_sys_context)
  procedure sys_context_level;

  --%test(APEX maps to g_apex)
  procedure apex_level;

  --%test(Unknown name returns -1)
  procedure unknown_level;

  --%test(NULL input returns -1)
  procedure null_level;

  --%test(Lowercase name is case sensitive and returns -1)
  procedure lowercase_level;

  --%test(Mixed case name returns -1)
  procedure mixed_case_level;

  --%test(Name with surrounding spaces returns -1)
  procedure padded_level;

  --%test(Empty string is treated as NULL and returns -1)
  procedure empty_string_level;

  --%test(Numeric string returns -1)
  procedure numeric_string_level;

  --%test(Result is consistent with convert_level_num_to_char round trip)
  procedure round_trip;

end test_logger_convert_level_char_to_num;
/
create or replace package body test_logger_convert_level_char_to_num as

  procedure off_level is
  begin
    ut.expect(logger.convert_level_char_to_num('OFF')).to_equal(logger.g_off);
    ut.expect(logger.convert_level_char_to_num(logger.g_off_name)).to_equal(0);
  end off_level;

  procedure permanent_level is
  begin
    ut.expect(logger.convert_level_char_to_num('PERMANENT')).to_equal(logger.g_permanent);
    ut.expect(logger.convert_level_char_to_num(logger.g_permanent_name)).to_equal(1);
  end permanent_level;

  procedure error_level is
  begin
    ut.expect(logger.convert_level_char_to_num('ERROR')).to_equal(logger.g_error);
    ut.expect(logger.convert_level_char_to_num(logger.g_error_name)).to_equal(2);
  end error_level;

  procedure warning_level is
  begin
    ut.expect(logger.convert_level_char_to_num('WARNING')).to_equal(logger.g_warning);
    ut.expect(logger.convert_level_char_to_num(logger.g_warning_name)).to_equal(4);
  end warning_level;

  procedure information_level is
  begin
    ut.expect(logger.convert_level_char_to_num('INFORMATION')).to_equal(logger.g_information);
    ut.expect(logger.convert_level_char_to_num(logger.g_information_name)).to_equal(8);
  end information_level;

  procedure debug_level is
  begin
    ut.expect(logger.convert_level_char_to_num('DEBUG')).to_equal(logger.g_debug);
    ut.expect(logger.convert_level_char_to_num(logger.g_debug_name)).to_equal(16);
  end debug_level;

  procedure timing_level is
  begin
    ut.expect(logger.convert_level_char_to_num('TIMING')).to_equal(logger.g_timing);
    ut.expect(logger.convert_level_char_to_num(logger.g_timing_name)).to_equal(32);
  end timing_level;

  procedure sys_context_level is
  begin
    ut.expect(logger.convert_level_char_to_num('SYS_CONTEXT')).to_equal(logger.g_sys_context);
    ut.expect(logger.convert_level_char_to_num(logger.g_sys_context_name)).to_equal(64);
  end sys_context_level;

  procedure apex_level is
  begin
    ut.expect(logger.convert_level_char_to_num('APEX')).to_equal(logger.g_apex);
    ut.expect(logger.convert_level_char_to_num(logger.g_apex_name)).to_equal(128);
  end apex_level;

  procedure unknown_level is
  begin
    ut.expect(logger.convert_level_char_to_num('NOT_A_LEVEL')).to_equal(-1);
  end unknown_level;

  procedure null_level is
  begin
    ut.expect(logger.convert_level_char_to_num(null)).to_equal(-1);
  end null_level;

  procedure lowercase_level is
  begin
    ut.expect(logger.convert_level_char_to_num('debug')).to_equal(-1);
    ut.expect(logger.convert_level_char_to_num('error')).to_equal(-1);
  end lowercase_level;

  procedure mixed_case_level is
  begin
    ut.expect(logger.convert_level_char_to_num('Debug')).to_equal(-1);
  end mixed_case_level;

  procedure padded_level is
  begin
    ut.expect(logger.convert_level_char_to_num(' DEBUG')).to_equal(-1);
    ut.expect(logger.convert_level_char_to_num('DEBUG ')).to_equal(-1);
  end padded_level;

  procedure empty_string_level is
  begin
    ut.expect(logger.convert_level_char_to_num('')).to_equal(-1);
  end empty_string_level;

  procedure numeric_string_level is
  begin
    ut.expect(logger.convert_level_char_to_num('16')).to_equal(-1);
  end numeric_string_level;

  procedure round_trip is
    l_names sys.odcivarchar2list := sys.odcivarchar2list(
      logger.g_off_name, logger.g_permanent_name, logger.g_error_name,
      logger.g_warning_name, logger.g_information_name, logger.g_debug_name,
      logger.g_timing_name, logger.g_sys_context_name, logger.g_apex_name);
    l_num number;
  begin
    for i in 1 .. l_names.count loop
      l_num := logger.convert_level_char_to_num(l_names(i));
      ut.expect(l_num).to_be_greater_than(-1);
      ut.expect(logger.convert_level_num_to_char(l_num)).to_equal(l_names(i));
    end loop;
  end round_trip;

end test_logger_convert_level_char_to_num;
/
