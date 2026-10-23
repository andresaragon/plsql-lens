create or replace package test_pkg_text_is_palindrome as
  --%suite(pkg_text.is_palindrome tests)

  --%test(Simple odd-length palindrome returns TRUE)
  procedure odd_palindrome;

  --%test(Simple even-length palindrome returns TRUE)
  procedure even_palindrome;

  --%test(Mixed case palindrome ignores case)
  procedure mixed_case;

  --%test(Phrase with spaces and punctuation returns TRUE)
  procedure phrase_with_punctuation;

  --%test(Numeric palindrome returns TRUE)
  procedure numeric_palindrome;

  --%test(Alphanumeric palindrome returns TRUE)
  procedure alphanumeric_palindrome;

  --%test(Non palindrome returns FALSE)
  procedure not_palindrome;

  --%test(Non palindrome with mismatch only in outer characters returns FALSE)
  procedure mismatch_outer;

  --%test(Non palindrome with mismatch in inner characters returns FALSE)
  procedure mismatch_inner;

  --%test(Even-length non palindrome returns FALSE)
  procedure even_not_palindrome;

  --%test(Numeric non palindrome returns FALSE)
  procedure numeric_not_palindrome;

  --%test(Single character returns TRUE)
  procedure single_char;

  --%test(Two identical characters returns TRUE)
  procedure two_same_chars;

  --%test(Two different characters returns FALSE)
  procedure two_different_chars;

  --%test(Single character surrounded by punctuation returns TRUE)
  procedure single_char_with_punctuation;

  --%test(Punctuation differences are ignored)
  procedure punctuation_ignored;

  --%test(NULL returns FALSE)
  procedure null_input;

  --%test(Empty string returns FALSE)
  procedure empty_input;

  --%test(Only spaces returns FALSE)
  procedure only_spaces;

  --%test(Only punctuation returns FALSE)
  procedure only_punctuation;

  --%test(Maximum length palindrome of 4000 characters returns TRUE)
  procedure max_length_palindrome;

  --%test(Maximum length non palindrome returns FALSE)
  procedure max_length_not_palindrome;
end test_pkg_text_is_palindrome;
/
create or replace package body test_pkg_text_is_palindrome as

  procedure odd_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('racecar')).to_be_true();
  end odd_palindrome;

  procedure even_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('abba')).to_be_true();
  end even_palindrome;

  procedure mixed_case is
  begin
    ut.expect(pkg_text.is_palindrome('RaceCar')).to_be_true();
  end mixed_case;

  procedure phrase_with_punctuation is
  begin
    ut.expect(pkg_text.is_palindrome('A man, a plan, a canal: Panama')).to_be_true();
  end phrase_with_punctuation;

  procedure numeric_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('12321')).to_be_true();
  end numeric_palindrome;

  procedure alphanumeric_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('a1b2b1a')).to_be_true();
  end alphanumeric_palindrome;

  procedure not_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('hello')).to_be_false();
  end not_palindrome;

  procedure mismatch_outer is
  begin
    ut.expect(pkg_text.is_palindrome('abcda')).to_be_false();
  end mismatch_outer;

  procedure mismatch_inner is
  begin
    ut.expect(pkg_text.is_palindrome('abcbd')).to_be_false();
  end mismatch_inner;

  procedure even_not_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('abca')).to_be_false();
  end even_not_palindrome;

  procedure numeric_not_palindrome is
  begin
    ut.expect(pkg_text.is_palindrome('12345')).to_be_false();
  end numeric_not_palindrome;

  procedure single_char is
  begin
    ut.expect(pkg_text.is_palindrome('x')).to_be_true();
  end single_char;

  procedure two_same_chars is
  begin
    ut.expect(pkg_text.is_palindrome('aa')).to_be_true();
  end two_same_chars;

  procedure two_different_chars is
  begin
    ut.expect(pkg_text.is_palindrome('ab')).to_be_false();
  end two_different_chars;

  procedure single_char_with_punctuation is
  begin
    ut.expect(pkg_text.is_palindrome('--a!!')).to_be_true();
  end single_char_with_punctuation;

  procedure punctuation_ignored is
  begin
    ut.expect(pkg_text.is_palindrome('ab-c.ba')).to_be_true();
  end punctuation_ignored;

  procedure null_input is
  begin
    ut.expect(pkg_text.is_palindrome(null)).to_be_false();
  end null_input;

  procedure empty_input is
  begin
    ut.expect(pkg_text.is_palindrome('')).to_be_false();
  end empty_input;

  procedure only_spaces is
  begin
    ut.expect(pkg_text.is_palindrome('     ')).to_be_false();
  end only_spaces;

  procedure only_punctuation is
  begin
    ut.expect(pkg_text.is_palindrome('!?.,-;:')).to_be_false();
  end only_punctuation;

  procedure max_length_palindrome is
    l_text varchar2(4000) := rpad('a', 4000, 'a');
  begin
    ut.expect(pkg_text.is_palindrome(l_text)).to_be_true();
  end max_length_palindrome;

  procedure max_length_not_palindrome is
    l_text varchar2(4000) := 'b' || rpad('a', 3999, 'a');
  begin
    ut.expect(pkg_text.is_palindrome(l_text)).to_be_false();
  end max_length_not_palindrome;

end test_pkg_text_is_palindrome;
/
