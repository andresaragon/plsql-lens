create or replace package test_logger_sprintf as
  --%suite(logger.sprintf)

  --%test(Returns the string unchanged when there are no placeholders)
  procedure no_placeholders;

  --%test(Replaces sequential %s placeholders in order)
  procedure sequential_placeholders;

  --%test(Replaces numbered placeholders %s1 and %s2 out of order)
  procedure numbered_placeholders_reordered;

  --%test(Same numbered placeholder can be used several times)
  procedure numbered_placeholder_repeated;

  --%test(Numbered placeholder with NULL value is replaced by empty string)
  procedure numbered_placeholder_null_value;

  --%test(Double percent is escaped to a single percent)
  procedure escaped_percent;

  --%test(NULL input string returns NULL)
  procedure null_input_string;

  --%test(Nine numbered placeholders are all replaced)
  procedure nine_numbered_placeholders;

  --%test(Ten sequential placeholders are all replaced)
  procedure ten_sequential_placeholders;

  --%test(Text around placeholders is preserved)
  procedure surrounding_text_preserved;

  --%test(Numbered placeholder without a following digit match is left to sequential logic)
  procedure mixed_text_and_numbered;
end test_logger_sprintf;
/
create or replace package body test_logger_sprintf as

  procedure no_placeholders is
  begin
    ut.expect(logger.sprintf('Hello World')).to_equal('Hello World');
  end;

  procedure sequential_placeholders is
  begin
    ut.expect(logger.sprintf('%s and %s', 'a', 'b')).to_equal('a and b');
  end;

  procedure numbered_placeholders_reordered is
  begin
    ut.expect(logger.sprintf('%s2 %s1', 'first', 'second')).to_equal('second first');
  end;

  procedure numbered_placeholder_repeated is
  begin
    ut.expect(logger.sprintf('%s1-%s1', 'x')).to_equal('x-x');
  end;

  procedure numbered_placeholder_null_value is
  begin
    ut.expect(logger.sprintf('a%s1b', null)).to_equal('ab');
  end;

  procedure escaped_percent is
  begin
    ut.expect(logger.sprintf('100%%')).to_equal('100%');
  end;

  procedure null_input_string is
  begin
    ut.expect(logger.sprintf(null, 'a', 'b')).to_be_null();
  end;

  procedure nine_numbered_placeholders is
  begin
    ut.expect(
      logger.sprintf('%s1,%s2,%s3,%s4,%s5,%s6,%s7,%s8,%s9',
                     'a','b','c','d','e','f','g','h','i')
    ).to_equal('a,b,c,d,e,f,g,h,i');
  end;

  procedure ten_sequential_placeholders is
  begin
    ut.expect(
      logger.sprintf('%s,%s,%s,%s,%s,%s,%s,%s,%s,%s',
                     'a','b','c','d','e','f','g','h','i','j')
    ).to_equal('a,b,c,d,e,f,g,h,i,j');
  end;

  procedure surrounding_text_preserved is
  begin
    ut.expect(logger.sprintf('Hello %s, welcome to %s!', 'Bob', 'Oracle'))
      .to_equal('Hello Bob, welcome to Oracle!');
  end;

  procedure mixed_text_and_numbered is
  begin
    ut.expect(logger.sprintf('[%s2] [%s1] done', 'one', 'two'))
      .to_equal('[two] [one] done');
  end;

end test_logger_sprintf;
/
