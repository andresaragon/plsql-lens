create or replace package test_logger_convert_level_num_to_char as

  --%suite(logger.convert_level_num_to_char)

  --%test(OFF level 0 returns OFF)
  procedure test_off;

  --%test(PERMANENT level 1 returns PERMANENT)
  procedure test_permanent;

  --%test(ERROR level 2 returns ERROR)
  procedure test_error;

  --%test(WARNING level 4 returns WARNING)
  procedure test_warning;

  --%test(INFORMATION level 8 returns INFORMATION)
  procedure test_information;

  --%test(DEBUG level 16 returns DEBUG)
  procedure test_debug;

  --%test(TIMING level 32 returns TIMING)
  procedure test_timing;

  --%test(SYS_CONTEXT level 64 returns SYS_CONTEXT)
  procedure test_sys_context;

  --%test(APEX level 128 returns APEX)
  procedure test_apex;

  --%test(NULL input returns NULL)
  procedure test_null_input;

  --%test(Unknown value 3 returns NULL)
  procedure test_unknown_between;

  --%test(Negative value returns NULL)
  procedure test_negative;

  --%test(Value above max 256 returns NULL)
  procedure test_above_max;

  --%test(Fractional value returns NULL)
  procedure test_fractional;

  --%test(Constants map to their names)
  procedure test_constants_mapping;

end test_logger_convert_level_num_to_char;
/
create or replace package body test_logger_convert_level_num_to_char as

  procedure test_off is
  begin
    ut.expect(logger.convert_level_num_to_char(0)).to_equal('OFF');
  end;

  procedure test_permanent is
  begin
    ut.expect(logger.convert_level_num_to_char(1)).to_equal('PERMANENT');
  end;

  procedure test_error is
  begin
    ut.expect(logger.convert_level_num_to_char(2)).to_equal('ERROR');
  end;

  procedure test_warning is
  begin
    ut.expect(logger.convert_level_num_to_char(4)).to_equal('WARNING');
  end;

  procedure test_information is
  begin
    ut.expect(logger.convert_level_num_to_char(8)).to_equal('INFORMATION');
  end;

  procedure test_debug is
  begin
    ut.expect(logger.convert_level_num_to_char(16)).to_equal('DEBUG');
  end;

  procedure test_timing is
  begin
    ut.expect(logger.convert_level_num_to_char(32)).to_equal('TIMING');
  end;

  procedure test_sys_context is
  begin
    ut.expect(logger.convert_level_num_to_char(64)).to_equal('SYS_CONTEXT');
  end;

  procedure test_apex is
  begin
    ut.expect(logger.convert_level_num_to_char(128)).to_equal('APEX');
  end;

  procedure test_null_input is
  begin
    ut.expect(logger.convert_level_num_to_char(null)).to_be_null();
  end;

  procedure test_unknown_between is
  begin
    ut.expect(logger.convert_level_num_to_char(3)).to_be_null();
  end;

  procedure test_negative is
  begin
    ut.expect(logger.convert_level_num_to_char(-1)).to_be_null();
  end;

  procedure test_above_max is
  begin
    ut.expect(logger.convert_level_num_to_char(256)).to_be_null();
  end;

  procedure test_fractional is
  begin
    ut.expect(logger.convert_level_num_to_char(1.5)).to_be_null();
  end;

  procedure test_constants_mapping is
  begin
    ut.expect(logger.convert_level_num_to_char(logger.g_off)).to_equal(logger.g_off_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_permanent)).to_equal(logger.g_permanent_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_error)).to_equal(logger.g_error_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_warning)).to_equal(logger.g_warning_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_information)).to_equal(logger.g_information_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_debug)).to_equal(logger.g_debug_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_timing)).to_equal(logger.g_timing_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_sys_context)).to_equal(logger.g_sys_context_name);
    ut.expect(logger.convert_level_num_to_char(logger.g_apex)).to_equal(logger.g_apex_name);
  end;

end test_logger_convert_level_num_to_char;
/
