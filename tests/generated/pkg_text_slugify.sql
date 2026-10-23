create or replace package test_pkg_text_slugify as
  --%suite(pkg_text.slugify tests)

  --%test(Simple text is lower-cased)
  procedure lowercases_simple_text;

  --%test(Spaces become a single hyphen)
  procedure spaces_to_hyphen;

  --%test(Runs of non-alphanumerics collapse into one hyphen)
  procedure collapses_runs;

  --%test(Leading and trailing separators are removed)
  procedure trims_edges;

  --%test(NULL input returns NULL)
  procedure null_returns_null;

  --%test(Empty string is treated as NULL by Oracle and returns NULL)
  procedure empty_returns_null;

  --%test(Only separators returns NULL)
  procedure only_separators;

  --%test(Digits are preserved)
  procedure digits_preserved;

  --%test(Single character input)
  procedure single_char;

  --%test(Already a slug is unchanged)
  procedure already_slug;

  --%test(Mixed case and punctuation)
  procedure mixed_punctuation;

  --%test(Non-ASCII letters are treated as separators)
  procedure non_ascii_separator;
end test_pkg_text_slugify;
/
create or replace package body test_pkg_text_slugify as

  procedure lowercases_simple_text is
  begin
    ut.expect(pkg_text.slugify('HELLO')).to_equal('hello');
  end;

  procedure spaces_to_hyphen is
  begin
    ut.expect(pkg_text.slugify('Hello World')).to_equal('hello-world');
  end;

  procedure collapses_runs is
  begin
    ut.expect(pkg_text.slugify('a   b!!!c___d')).to_equal('a-b-c-d');
  end;

  procedure trims_edges is
  begin
    ut.expect(pkg_text.slugify('  --Hello World!!  ')).to_equal('hello-world');
  end;

  procedure null_returns_null is
  begin
    ut.expect(pkg_text.slugify(null)).to_be_null();
  end;

  procedure empty_returns_null is
  begin
    ut.expect(pkg_text.slugify('')).to_be_null();
  end;

  procedure only_separators is
  begin
    ut.expect(pkg_text.slugify('  !!! --- ')).to_be_null();
  end;

  procedure digits_preserved is
  begin
    ut.expect(pkg_text.slugify('Version 2.0 Release 10')).to_equal('version-2-0-release-10');
  end;

  procedure single_char is
  begin
    ut.expect(pkg_text.slugify('A')).to_equal('a');
  end;

  procedure already_slug is
  begin
    ut.expect(pkg_text.slugify('already-a-slug-123')).to_equal('already-a-slug-123');
  end;

  procedure mixed_punctuation is
  begin
    ut.expect(pkg_text.slugify('Hello, World! It''s 5 o''clock.')).to_equal('hello-world-it-s-5-o-clock');
  end;

  procedure non_ascii_separator is
  begin
    ut.expect(pkg_text.slugify('caf' || unistr('\00E9') || ' bar')).to_equal('caf-bar');
  end;

end test_pkg_text_slugify;
/
