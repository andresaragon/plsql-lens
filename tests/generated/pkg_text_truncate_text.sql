create or replace package test_pkg_text_truncate_text as
  --%suite(pkg_text.truncate_text)

  --%test(Text shorter than max length is returned unchanged)
  procedure shorter_text_unchanged;

  --%test(Text exactly as long as max length is returned unchanged)
  procedure exact_length_unchanged;

  --%test(Text one char over max length is truncated with ellipsis)
  procedure one_over_is_truncated;

  --%test(Long text is cut to max length ending with ellipsis)
  procedure long_text_truncated;

  --%test(Minimum allowed max length 4 keeps one char plus ellipsis)
  procedure min_allowed_max_len;

  --%test(Minimum max length 4 with text of length 4 is unchanged)
  procedure min_len_text_fits;

  --%test(Result length never exceeds max length)
  procedure result_length_within_max;

  --%test(NULL text returns NULL as documented)
  procedure null_text_returns_null;

  --%test(Max length 3 raises ORA-20002)
  --%throws(-20002)
  procedure max_len_3_raises;

  --%test(Max length 0 raises ORA-20002)
  --%throws(-20002)
  procedure max_len_0_raises;

  --%test(Negative max length raises ORA-20002)
  --%throws(-20002)
  procedure max_len_negative_raises;

  --%test(Invalid max length raises even when text is NULL)
  --%throws(-20002)
  procedure max_len_invalid_null_text_raises;
end test_pkg_text_truncate_text;
/
create or replace package body test_pkg_text_truncate_text as

  procedure shorter_text_unchanged is
  begin
    ut.expect(pkg_text.truncate_text('abc', 10)).to_equal('abc');
  end shorter_text_unchanged;

  procedure exact_length_unchanged is
  begin
    ut.expect(pkg_text.truncate_text('abcde', 5)).to_equal('abcde');
  end exact_length_unchanged;

  procedure one_over_is_truncated is
  begin
    ut.expect(pkg_text.truncate_text('abcdef', 5)).to_equal('ab...');
  end one_over_is_truncated;

  procedure long_text_truncated is
  begin
    ut.expect(pkg_text.truncate_text('The quick brown fox jumps', 10)).to_equal('The qui...');
  end long_text_truncated;

  procedure min_allowed_max_len is
  begin
    ut.expect(pkg_text.truncate_text('abcdef', 4)).to_equal('a...');
  end min_allowed_max_len;

  procedure min_len_text_fits is
  begin
    ut.expect(pkg_text.truncate_text('abcd', 4)).to_equal('abcd');
  end min_len_text_fits;

  procedure result_length_within_max is
    l_result varchar2(4000);
  begin
    l_result := pkg_text.truncate_text(rpad('x', 100, 'x'), 20);
    ut.expect(length(l_result)).to_equal(20);
    ut.expect(substr(l_result, -3)).to_equal('...');
  end result_length_within_max;

  procedure null_text_returns_null is
  begin
    ut.expect(pkg_text.truncate_text(null, 10)).to_be_null();
  end null_text_returns_null;

  procedure max_len_3_raises is
    l_result varchar2(4000);
  begin
    l_result := pkg_text.truncate_text('abcdef', 3);
  end max_len_3_raises;

  procedure max_len_0_raises is
    l_result varchar2(4000);
  begin
    l_result := pkg_text.truncate_text('abcdef', 0);
  end max_len_0_raises;

  procedure max_len_negative_raises is
    l_result varchar2(4000);
  begin
    l_result := pkg_text.truncate_text('abcdef', -5);
  end max_len_negative_raises;

  procedure max_len_invalid_null_text_raises is
    l_result varchar2(4000);
  begin
    l_result := pkg_text.truncate_text(null, 2);
  end max_len_invalid_null_text_raises;

end test_pkg_text_truncate_text;
/
