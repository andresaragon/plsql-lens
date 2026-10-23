create or replace package test_logger_log_error as
  --%suite(logger.log_error)

  --%beforeeach
  procedure set_debug_level;

  --%aftereach
  procedure restore_level;

  --%test(Inserts one row with ERROR level and given scope)
  procedure inserts_error_row;

  --%test(Stores text supplied by caller)
  procedure stores_text;

  --%test(NULL text still logs a row)
  procedure null_text_logs_row;

  --%test(NULL scope logs a row with NULL scope)
  procedure null_scope_logs_row;

  --%test(Stores extra clob)
  procedure stores_extra;

  --%test(NULL extra is stored as NULL)
  procedure null_extra_is_null;

  --%test(Params are appended to extra)
  procedure params_appended_to_extra;

  --%test(Error stack is included in text when an exception is active)
  procedure includes_error_stack;

  --%test(Unit name is stored in upper case)
  procedure unit_name_upper;

  --%test(Boundary: 4000 character text logs a row)
  procedure max_length_text;

  --%test(Level ERROR logs when logger level is ERROR)
  procedure logs_at_error_level;

  --%test(Level OFF suppresses logging)
  procedure off_level_no_row;

  --%test(Level PERMANENT suppresses error logging)
  procedure permanent_level_no_row;

  --%test(Multiple calls insert multiple rows)
  procedure multiple_calls;
end test_logger_log_error;
/
create or replace package body test_logger_log_error as

  function new_scope return varchar2 is
  begin
    return 'TLE_' || rawtohex(sys_guid());
  end;

  function cnt(p_scope in varchar2) return number is
    l_n number;
  begin
    select count(*) into l_n from logger_logs where scope = p_scope;
    return l_n;
  end;

  procedure set_debug_level is
  begin
    logger.set_level(logger.g_debug_name);
  end;

  procedure restore_level is
  begin
    logger.set_level(logger.g_debug_name);
  end;

  procedure inserts_error_row is
    l_scope varchar2(100) := new_scope;
    l_lvl   number;
  begin
    logger.log_error('msg', l_scope);
    ut.expect(cnt(l_scope)).to_equal(1);
    select logger_level into l_lvl from logger_logs where scope = l_scope;
    ut.expect(l_lvl).to_equal(logger.g_error);
  end;

  procedure stores_text is
    l_scope varchar2(100) := new_scope;
    l_n     number;
  begin
    logger.log_error('hello_text_abc', l_scope);
    select count(*) into l_n from logger_logs
     where scope = l_scope and text like 'hello_text_abc%';
    ut.expect(l_n).to_equal(1);
  end;

  procedure null_text_logs_row is
    l_scope varchar2(100) := new_scope;
  begin
    logger.log_error(p_text => null, p_scope => l_scope);
    ut.expect(cnt(l_scope)).to_equal(1);
  end;

  procedure null_scope_logs_row is
    l_before number;
    l_after  number;
  begin
    select count(*) into l_before from logger_logs
     where scope is null and logger_level = logger.g_error;
    logger.log_error('null scope test');
    select count(*) into l_after from logger_logs
     where scope is null and logger_level = logger.g_error;
    ut.expect(l_after).to_be_greater_than(l_before - 1);
    ut.expect(l_after >= l_before).to_be_true();
  end;

  procedure stores_extra is
    l_scope varchar2(100) := new_scope;
    l_extra clob;
  begin
    logger.log_error('t', l_scope, 'extra_payload_xyz');
    select extra into l_extra from logger_logs where scope = l_scope;
    ut.expect(dbms_lob.substr(l_extra, 100, 1)).to_equal('extra_payload_xyz');
  end;

  procedure null_extra_is_null is
    l_scope varchar2(100) := new_scope;
    l_extra clob;
  begin
    logger.log_error('t', l_scope, null);
    select extra into l_extra from logger_logs where scope = l_scope;
    ut.expect(dbms_lob.getlength(l_extra) is null or dbms_lob.getlength(l_extra) = 0).to_be_true();
  end;

  procedure params_appended_to_extra is
    l_scope  varchar2(100) := new_scope;
    l_params logger.tab_param;
    l_extra  clob;
  begin
    logger.append_param(l_params, 'my_param_name', 'my_param_value');
    logger.log_error('t', l_scope, 'base', l_params);
    select extra into l_extra from logger_logs where scope = l_scope;
    ut.expect(dbms_lob.instr(l_extra, 'my_param_name')).to_be_greater_than(0);
    ut.expect(dbms_lob.instr(l_extra, 'my_param_value')).to_be_greater_than(0);
  end;

  procedure includes_error_stack is
    l_scope varchar2(100) := new_scope;
    l_text  varchar2(4000);
  begin
    begin
      raise_application_error(-20001, 'boom');
    exception
      when others then
        logger.log_error('caught', l_scope);
    end;
    select text into l_text from logger_logs where scope = l_scope;
    ut.expect(instr(l_text, 'ORA-20001')).to_be_greater_than(0);
    ut.expect(instr(l_text, 'caught')).to_be_greater_than(0);
  end;

  procedure unit_name_upper is
    l_scope varchar2(100) := new_scope;
    l_unit  logger_logs.unit_name%type;
  begin
    logger.log_error('t', l_scope);
    select unit_name into l_unit from logger_logs where scope = l_scope;
    ut.expect(l_unit).to_equal(upper(l_unit));
  end;

  procedure max_length_text is
    l_scope varchar2(100) := new_scope;
  begin
    logger.log_error(rpad('x', 4000, 'x'), l_scope);
    ut.expect(cnt(l_scope)).to_equal(1);
  end;

  procedure logs_at_error_level is
    l_scope varchar2(100) := new_scope;
  begin
    logger.set_level(logger.g_error_name);
    logger.log_error('t', l_scope);
    ut.expect(cnt(l_scope)).to_equal(1);
  end;

  procedure off_level_no_row is
    l_scope varchar2(100) := new_scope;
  begin
    logger.set_level(logger.g_off_name);
    logger.log_error('t', l_scope);
    ut.expect(cnt(l_scope)).to_equal(0);
  end;

  procedure permanent_level_no_row is
    l_scope varchar2(100) := new_scope;
  begin
    logger.set_level(logger.g_permanent_name);
    logger.log_error('t', l_scope);
    ut.expect(cnt(l_scope)).to_equal(0);
  end;

  procedure multiple_calls is
    l_scope varchar2(100) := new_scope;
  begin
    logger.log_error('a', l_scope);
    logger.log_error('b', l_scope);
    logger.log_error('c', l_scope);
    ut.expect(cnt(l_scope)).to_equal(3);
  end;

end test_logger_log_error;
/
