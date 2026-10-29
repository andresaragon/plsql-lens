




create or replace package body lib_catalog_search as

  function count_catalog_items(p_category in varchar2) return number is
    l_cnt number;
  begin
    execute immediate 'select count(*) from catalog_' || p_category into l_cnt;
    return l_cnt;
  end count_catalog_items;

  procedure find_book_by_isbn(p_isbn in varchar2, p_title out varchar2) is
  begin
    execute immediate 'select title from books where isbn = :b' into p_title using p_isbn;
  end find_book_by_isbn;

end lib_catalog_search;
/
