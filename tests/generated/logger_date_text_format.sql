create or replace package test_logger_date_text_format as
  --%suite(logger.date_text_format)

  --%test(Recent date returns non-null text)
  procedure recent_date_not_null;

  --%test(Date ten days in the past returns non-null text)
  procedure past_date_not_null;

  --%test(Very old date gives the same text on repeated calls)
  procedure old_date_is_stable;

  --%test(Very old date and very recent date give different text)
  procedure old_vs_recent_differ;

  --%test(Future date does not raise an error)
  procedure future_date_no_error;

  --%test(NULL date does not raise an error)
  procedure null_date_no_error;

  --%test(Result fits in a VARCHAR2 of 4000 characters)
  procedure result_length_bounded;
end test_logger_date_text_format;
/
create or replace package body test_logger_date_text_format as

  procedure recent_date_not_null is
    l_result varchar2(32767);
  begin
    l_result := logger.date_text_format(sysdate - 30 / 86400);
    ut.expect(l_result).to_be_not_null();
  end recent_date_not_null;

  procedure past_date_not_null is
    l_result varchar2(32767);
  begin
    l_result := logger.date_text_format(sysdate - 10);
    ut.expect(l_result).to_be_not_null();
  end past_date_not_null;

  procedure old_date_is_stable is
    l_first  varchar2(32767);
    l_second varchar2(32767);
  begin
    l_first  := logger.date_text_format(date '2000-01-01');
    l_second := logger.date_text_format(date '2000-01-01');
    ut.expect(l_first).to_equal(l_second);
  end old_date_is_stable;

  procedure old_vs_recent_differ is
    l_old    varchar2(32767);
    l_recent varchar2(32767);
  begin
    l_old    := logger.date_text_format(date '2000-01-01');
    l_recent := logger.date_text_format(sysdate - 5 / 86400);
    ut.expect(l_old).not_to_equal(l_recent);
  end old_vs_recent_differ;

  procedure future_date_no_error is
    l_result varchar2(32767);
  begin
    l_result := logger.date_text_format(sysdate + 10);
    ut.expect(l_result is null or length(l_result) > 0).to_be_true();
  end future_date_no_error;

  procedure null_date_no_error is
    l_result varchar2(32767);
  begin
    l_result := logger.date_text_format(null);
    ut.expect(l_result is null or length(l_result) > 0).to_be_true();
  end null_date_no_error;

  procedure result_length_bounded is
    l_result varchar2(32767);
  begin
    l_result := logger.date_text_format(date '1900-01-01');
    ut.expect(nvl(length(l_result), 0)).to_be_less_or_equal(4000);
  end result_length_bounded;

end test_logger_date_text_format;
/
