-- case: e013
-- domain: ticketing
-- difficulty: medium
-- note: ticket refund date processing comparing unmasked to_date with explicit date format mask
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body tkt_refund_date_ops as

  procedure parse_legacy_ticket_date(p_event_date in varchar2, p_out out date) is
    l_parsed date;
  begin
    l_parsed := to_date(p_event_date); -- expect: PLL006
    p_out := l_parsed;
  end parse_legacy_ticket_date;

  procedure parse_standard_ticket_date(p_event_date in varchar2, p_out out date) is
    l_parsed date;
  begin
    l_parsed := to_date(p_event_date, 'YYYY-MM-DD'); -- clean: PLL006
    p_out := l_parsed;
  end parse_standard_ticket_date;

end tkt_refund_date_ops;
/
