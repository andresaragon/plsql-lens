




create or replace package body tkt_seat_allocation as

  procedure reserve_seat(p_seat_id in number, p_seat_code out varchar2) is
    l_seat varchar2(20);
  begin
    select seat_code into l_seat from seats where id = p_seat_id;
    p_seat_code := l_seat;
  end reserve_seat;

  procedure open_event_ticket_cursor(p_event_id in number, p_cur out sys_refcursor) is
  begin
    open p_cur for 'select * from tickets where event_id = ' || p_event_id;
  end open_event_ticket_cursor;

  procedure get_max_seat_price(p_event in number, p_max out number) is
  begin
    select nvl(max(price), 0) into p_max from seats where event_id = p_event;
  end get_max_seat_price;

end tkt_seat_allocation;
/
