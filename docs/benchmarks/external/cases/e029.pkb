-- case: e029
-- domain: car rental
-- difficulty: medium
-- note: dynamic ref cursor search with raw string concatenation versus bind variable lookup
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body cr_driver_search as

  procedure search_rentals_by_driver(p_lic in varchar2, p_cur out sys_refcursor) is
    l_query varchar2(500);
  begin
    l_query := 'select * from rentals where driver_lic = ''' || p_lic || '''';
    open p_cur for l_query; -- expect: PLL002
  end search_rentals_by_driver;

  procedure get_rental_by_id(p_id in number, p_cur out sys_refcursor) is
    l_query varchar2(500);
  begin
    l_query := 'select * from rentals where id = :b';
    open p_cur for l_query using p_id; -- clean: PLL002
  end get_rental_by_id;

end cr_driver_search;
/
