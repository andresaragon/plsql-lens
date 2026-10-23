create or replace package test_logger_get_pref as
  --%suite(logger.get_pref)

  --%test(Returns value of a custom pref for given type)
  procedure custom_pref_found;

  --%test(Pref name and type are case insensitive)
  procedure case_insensitive_inputs;

  --%test(Unknown pref name returns null)
  procedure unknown_pref_returns_null;

  --%test(NULL pref name returns null)
  procedure null_name_returns_null;

  --%test(NULL pref type returns null)
  procedure null_type_returns_null;

  --%test(Default pref type is LOGGER)
  procedure default_type_is_logger;

  --%test(Same name under different types returns the matching value)
  procedure same_name_different_types;

  --%test(Existing name with wrong type returns null)
  procedure wrong_type_returns_null;

  --%test(Maximum length value 255 chars is returned intact)
  procedure max_length_value;

  --%test(Client identifier does not affect custom prefs)
  procedure client_identifier_ignored_for_custom;
end test_logger_get_pref;
/
create or replace package body test_logger_get_pref as

  procedure custom_pref_found is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_A', 'UT_PREF_FOUND', 'abc');

    l_val := logger.get_pref(p_pref_name => 'UT_PREF_FOUND', p_pref_type => 'UT_TYPE_A');
    ut.expect(l_val).to_equal('abc');
  end;

  procedure case_insensitive_inputs is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_B', 'UT_PREF_CASE', 'xyz');

    l_val := logger.get_pref(p_pref_name => 'ut_pref_case', p_pref_type => 'ut_type_b');
    ut.expect(l_val).to_equal('xyz');
  end;

  procedure unknown_pref_returns_null is
    l_val varchar2(4000);
  begin
    l_val := logger.get_pref(p_pref_name => 'UT_PREF_DOES_NOT_EXIST_1', p_pref_type => 'UT_TYPE_C');
    ut.expect(l_val).to_be_null();
  end;

  procedure null_name_returns_null is
    l_val varchar2(4000);
  begin
    l_val := logger.get_pref(p_pref_name => null, p_pref_type => 'UT_TYPE_D');
    ut.expect(l_val).to_be_null();
  end;

  procedure null_type_returns_null is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_E', 'UT_PREF_NULLTYPE', 'v');

    l_val := logger.get_pref(p_pref_name => 'UT_PREF_NULLTYPE', p_pref_type => null);
    ut.expect(l_val).to_be_null();
  end;

  procedure default_type_is_logger is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values (logger.g_pref_type_logger, 'UT_PREF_DEFAULT_TYPE', 'dflt');

    l_val := logger.get_pref('UT_PREF_DEFAULT_TYPE');
    ut.expect(l_val).to_equal('dflt');
  end;

  procedure same_name_different_types is
    l_v1 varchar2(4000);
    l_v2 varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_F1', 'UT_PREF_SHARED', 'one');
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_F2', 'UT_PREF_SHARED', 'two');

    l_v1 := logger.get_pref('UT_PREF_SHARED', 'UT_TYPE_F1');
    l_v2 := logger.get_pref('UT_PREF_SHARED', 'UT_TYPE_F2');
    ut.expect(l_v1).to_equal('one');
    ut.expect(l_v2).to_equal('two');
  end;

  procedure wrong_type_returns_null is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_G1', 'UT_PREF_WRONGTYPE', 'val');

    l_val := logger.get_pref('UT_PREF_WRONGTYPE', 'UT_TYPE_G2');
    ut.expect(l_val).to_be_null();
  end;

  procedure max_length_value is
    l_expected varchar2(255) := rpad('x', 255, 'y');
    l_val      varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_H', 'UT_PREF_MAXLEN', l_expected);

    l_val := logger.get_pref('UT_PREF_MAXLEN', 'UT_TYPE_H');
    ut.expect(length(l_val)).to_equal(255);
    ut.expect(l_val).to_equal(l_expected);
  end;

  procedure client_identifier_ignored_for_custom is
    l_val varchar2(4000);
  begin
    insert into logger_prefs(pref_type, pref_name, pref_value)
    values ('UT_TYPE_I', 'UT_PREF_CLIENT', 'sys');

    dbms_session.set_identifier('UT_CLIENT_ID_1');
    l_val := logger.get_pref('UT_PREF_CLIENT', 'UT_TYPE_I');
    dbms_session.clear_identifier;

    ut.expect(l_val).to_equal('sys');
  exception
    when others then
      dbms_session.clear_identifier;
      raise;
  end;

end test_logger_get_pref;
/
