




create or replace package body htl_tier_pricing as

  type t_rooms is table of varchar2(30);

  procedure query_rooms_by_tier(p_cat in varchar2) is
    l_rooms t_rooms;
  begin
    execute immediate 'select room_num from rooms where category = :c' bulk collect into l_rooms using p_cat;
  end query_rooms_by_tier;

  procedure check_special_rates(p_date_val in date) is
  begin
    if p_date_val > '2026-01-01' then
      null;
    end if;
  end check_special_rates;

end htl_tier_pricing;
/
