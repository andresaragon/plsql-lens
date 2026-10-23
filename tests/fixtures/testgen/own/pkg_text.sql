-- Written for this repo. String helpers with edge cases (NULLs, separators, short inputs).
create or replace package pkg_text as
  -- Lower-case URL slug: runs of non-alphanumerics become one '-', no leading/trailing '-'. NULL -> NULL.
  function slugify(p_text varchar2) return varchar2;
  -- 'john.doe@example.com' -> 'j***@example.com'. Returns NULL when there is no '@' or nothing before it.
  function mask_email(p_email varchar2) return varchar2;
  -- TRUE when the letters and digits read the same both ways, ignoring case and punctuation. NULL -> FALSE.
  function is_palindrome(p_text varchar2) return boolean;
  -- Cuts p_text to p_max_len characters, ending with '...' when something was removed.
  -- Raises ORA-20002 when p_max_len < 4. NULL -> NULL.
  function truncate_text(p_text varchar2, p_max_len pls_integer) return varchar2;
end pkg_text;
/
create or replace package body pkg_text as
  function slugify(p_text varchar2) return varchar2 is
  begin
    if p_text is null then
      return null;
    end if;
    return trim(both '-' from regexp_replace(lower(p_text), '[^a-z0-9]+', '-'));
  end slugify;

  function mask_email(p_email varchar2) return varchar2 is
    l_at pls_integer := instr(p_email, '@');
  begin
    if l_at < 2 then
      return null;
    end if;
    return substr(p_email, 1, 1) || '***' || substr(p_email, l_at);
  end mask_email;

  function is_palindrome(p_text varchar2) return boolean is
    l_clean varchar2(4000);
  begin
    if p_text is null then
      return false;
    end if;
    l_clean := lower(regexp_replace(p_text, '[^[:alnum:]]', ''));
    if l_clean is null then
      return false;
    end if;
    for i in 1 .. trunc(length(l_clean) / 2) loop
      if substr(l_clean, i, 1) <> substr(l_clean, -i, 1) then
        return false;
      end if;
    end loop;
    return true;
  end is_palindrome;

  function truncate_text(p_text varchar2, p_max_len pls_integer) return varchar2 is
  begin
    if p_max_len < 4 then
      raise_application_error(-20002, 'max length must be at least 4');
    end if;
    if length(p_text) <= p_max_len then
      return p_text;
    end if;
    return substr(p_text, 1, p_max_len - 3) || '...';
  end truncate_text;
end pkg_text;
/
