create or replace package test_pkg_text_mask_email as
  --%suite(pkg_text.mask_email)

  --%test(Masks a typical email address)
  procedure normal_email;

  --%test(Boundary: single character before the at sign)
  procedure single_char_local_part;

  --%test(Boundary: at sign is at position 1 returns NULL)
  procedure at_sign_first_returns_null;

  --%test(No at sign returns NULL)
  procedure no_at_sign_returns_null;

  --%test(NULL input returns NULL per documented contract)
  procedure null_input;

  --%test(Empty string input returns NULL per documented contract)
  procedure empty_input;

  --%test(Only the at sign returns NULL)
  procedure only_at_sign;

  --%test(Nothing after the at sign keeps the at sign)
  procedure nothing_after_at;

  --%test(Multiple at signs: first one is used)
  procedure multiple_at_signs;

  --%test(Output keeps the case of the first character and domain)
  procedure preserves_case;

  --%test(Long local part is hidden entirely)
  procedure long_local_part;
end test_pkg_text_mask_email;
/
create or replace package body test_pkg_text_mask_email as

  procedure normal_email is
  begin
    ut.expect(pkg_text.mask_email('john.doe@example.com')).to_equal('j***@example.com');
  end normal_email;

  procedure single_char_local_part is
  begin
    ut.expect(pkg_text.mask_email('a@b.com')).to_equal('a***@b.com');
  end single_char_local_part;

  procedure at_sign_first_returns_null is
  begin
    ut.expect(pkg_text.mask_email('@example.com')).to_be_null();
  end at_sign_first_returns_null;

  procedure no_at_sign_returns_null is
  begin
    ut.expect(pkg_text.mask_email('john.doe.example.com')).to_be_null();
  end no_at_sign_returns_null;

  procedure null_input is
  begin
    ut.expect(pkg_text.mask_email(null)).to_be_null();
  end null_input;

  procedure empty_input is
  begin
    ut.expect(pkg_text.mask_email('')).to_be_null();
  end empty_input;

  procedure only_at_sign is
  begin
    ut.expect(pkg_text.mask_email('@')).to_be_null();
  end only_at_sign;

  procedure nothing_after_at is
  begin
    ut.expect(pkg_text.mask_email('ab@')).to_equal('a***@');
  end nothing_after_at;

  procedure multiple_at_signs is
  begin
    ut.expect(pkg_text.mask_email('ab@cd@ef.com')).to_equal('a***@cd@ef.com');
  end multiple_at_signs;

  procedure preserves_case is
  begin
    ut.expect(pkg_text.mask_email('JOHN@Example.COM')).to_equal('J***@Example.COM');
  end preserves_case;

  procedure long_local_part is
  begin
    ut.expect(pkg_text.mask_email(rpad('x', 200, 'y') || '@host.org')).to_equal('x***@host.org');
  end long_local_part;

end test_pkg_text_mask_email;
/
