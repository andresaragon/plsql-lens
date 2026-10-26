-- case: e014
-- domain: ticketing
-- difficulty: hard
-- note: event cancellation dispatch calling refund subprogram that executes dml inside loop
-- author: gemini-3.8-flash-high via agy (not human-written)
create or replace package body tkt_cancellation_dispatch as

  procedure cancel_ticket_order(p_order_id in number) is
  begin
    update ticket_orders set status = 'CANCELLED' where order_id = p_order_id;
    commit; -- clean: PLL003
  end cancel_ticket_order;

  procedure process_bulk_cancellations(p_event_id in number) is
  begin
    for r in (select order_id from ticket_orders where event_id = p_event_id) loop
      dispatch_refund_notice(r.order_id); -- beyond: PLL005 (subprogram called inside loop performs DML)
    end loop;
  end process_bulk_cancellations;

end tkt_cancellation_dispatch;
/
