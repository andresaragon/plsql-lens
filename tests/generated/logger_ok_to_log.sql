create or replace package test_logger_ok_to_log as
  --%suite(logger.ok_to_log)
  --%rollback(manual)

  --%aftereach
  procedure cleanup;

  --%test(Numeric: level equal to configured level returns true)
  procedure num_equal_level;

  --%test(Numeric: lower (more severe) level returns true)
  procedure num_lower_level;

  --%test(Numeric: higher (more verbose) level returns false)
  procedure num_higher_level;

  --%test(Numeric: boundary just above configured level returns false)
  procedure num_boundary_above;

  --%test(Numeric: level OFF blocks errors)
  procedure num_off_blocks_error;

  --%test(Numeric: OFF level argument is always ok when level is OFF)
  procedure num_off_arg_true;

  --%test(Numeric: NULL level returns false)
  procedure num_null_level;

  --%test(Varchar: level equal returns true)
  procedure chr_equal_level;

  --%test(Varchar: more severe level returns true)
  procedure chr_lower_level;

  --%test(Varchar: more verbose level returns false)
  procedure chr_higher_level;

  --%test(Varchar: OFF configured blocks ERROR)
  procedure chr_off_blocks_error;

  --%test(Varchar overload is consistent with numeric overload)
  procedure chr_matches_num;

  --%test(Changing the level changes the result)
  procedure level_change;
end test_logger_ok_to_log;
/
create or replace package body test_logger_ok_to_log as
  c_client constant varchar2(64) := 'UT_OK_TO_LOG';

  procedure use_level(p_level in varchar2) is
  begin
    logger.set_level(p_level => p_level, p_client_id => c_client);
    dbms_session.set_identifier(c_client);
  end use_level;

  procedure cleanup is
  begin
    begin
      logger.unset_client_level(p_client_id => c_client);
    exception
      when others then null;
    end;
    dbms_session.clear_identifier;
  end cleanup;

  procedure num_equal_level is
  begin
    use_level(logger.g_debug_name);
    ut.expect(logger.ok_to_log(logger.g_debug)).to_be_true();
  end;

  procedure num_lower_level is
  begin
    use_level(logger.g_debug_name);
    ut.expect(logger.ok_to_log(logger.g_error)).to_be_true();
    ut.expect(logger.ok_to_log(logger.g_permanent)).to_be_true();
  end;

  procedure num_higher_level is
  begin
    use_level(logger.g_error_name);
    ut.expect(logger.ok_to_log(logger.g_debug)).to_be_false();
    ut.expect(logger.ok_to_log(logger.g_information)).to_be_false();
  end;

  procedure num_boundary_above is
  begin
    use_level(logger.g_debug_name);
    ut.expect(logger.ok_to_log(logger.g_debug + 1)).to_be_false();
    ut.expect(logger.ok_to_log(logger.g_timing)).to_be_false();
  end;

  procedure num_off_blocks_error is
  begin
    use_level(logger.g_off_name);
    ut.expect(logger.ok_to_log(logger.g_error)).to_be_false();
  end;

  procedure num_off_arg_true is
  begin
    use_level(logger.g_off_name);
    ut.expect(logger.ok_to_log(logger.g_off)).to_be_true();
  end;

  procedure num_null_level is
  begin
    use_level(logger.g_debug_name);
    ut.expect(logger.ok_to_log(cast(null as number))).to_be_false();
  end;

  procedure chr_equal_level is
  begin
    use_level(logger.g_debug_name);
    ut.expect(logger.ok_to_log(logger.g_debug_name)).to_be_true();
  end;

  procedure chr_lower_level is
  begin
    use_level(logger.g_information_name);
    ut.expect(logger.ok_to_log(logger.g_error_name)).to_be_true();
    ut.expect(logger.ok_to_log(logger.g_warning_name)).to_be_true();
  end;

  procedure chr_higher_level is
  begin
    use_level(logger.g_warning_name);
    ut.expect(logger.ok_to_log(logger.g_debug_name)).to_be_false();
    ut.expect(logger.ok_to_log(logger.g_information_name)).to_be_false();
  end;

  procedure chr_off_blocks_error is
  begin
    use_level(logger.g_off_name);
    ut.expect(logger.ok_to_log(logger.g_error_name)).to_be_false();
  end;

  procedure chr_matches_num is
    l_num boolean;
    l_chr boolean;
  begin
    use_level(logger.g_information_name);
    l_num := logger.ok_to_log(logger.g_debug);
    l_chr := logger.ok_to_log(logger.g_debug_name);
    ut.expect(l_chr).to_equal(l_num);
    l_num := logger.ok_to_log(logger.g_error);
    l_chr := logger.ok_to_log(logger.g_error_name);
    ut.expect(l_chr).to_equal(l_num);
  end;

  procedure level_change is
  begin
    use_level(logger.g_error_name);
    ut.expect(logger.ok_to_log(logger.g_debug)).to_be_false();
    logger.set_level(p_level => logger.g_debug_name, p_client_id => c_client);
    ut.expect(logger.ok_to_log(logger.g_debug)).to_be_true();
  end;
end test_logger_ok_to_log;
/
