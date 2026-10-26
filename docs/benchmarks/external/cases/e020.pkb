-- case: e020
-- domain: hotel booking
-- difficulty: easy
-- note: room booking cancellation with unprotected select into and safe exception-handled query
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body htl_booking_cancel as

  procedure cancel_room_booking(p_res_id in number) is
    l_guest varchar2(100);
    l_zero number;
  begin
    l_zero := 0; -- clean: PLL007
    select guest_name into l_guest from reservations where res_id = p_res_id; -- expect: PLL004
    update reservations set status = 'CANCELLED' where res_id = p_res_id;
  end cancel_room_booking;

  procedure inspect_room_availability(p_room in number, p_status out varchar2) is
  begin
    select status into p_status from rooms where room_id = p_room; -- clean: PLL004
  exception
    when no_data_found then
      p_status := 'UNKNOWN';
  end inspect_room_availability;

end htl_booking_cancel;
/
