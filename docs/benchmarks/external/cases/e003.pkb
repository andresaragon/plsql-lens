-- case: e003
-- domain: library loans
-- difficulty: medium
-- note: dynamic catalog search with string concatenation injection risk and parameterized alternative
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body lib_catalog_search as

  function count_catalog_items(p_category in varchar2) return number is
    l_cnt number;
  begin
    execute immediate 'select count(*) from catalog_' || p_category into l_cnt; -- expect: PLL002
    return l_cnt;
  end count_catalog_items;

  procedure find_book_by_isbn(p_isbn in varchar2, p_title out varchar2) is
  begin
    execute immediate 'select title from books where isbn = :b' into p_title using p_isbn; -- clean: PLL002
  end find_book_by_isbn;

end lib_catalog_search;
/
