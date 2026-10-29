




create or replace package body tkt_cancellation_dispatch as

  procedure cancel_ticket_order(p_order_id in number) is
  begin
    update ticket_orders set status = 'CANCELLED' where order_id = p_order_id;
    commit;
  end cancel_ticket_order;

  procedure process_bulk_cancellations(p_event_id in number) is
  begin
    for r in (select order_id from ticket_orders where event_id = p_event_id) loop
      dispatch_refund_notice(r.order_id);
    end loop;
  end process_bulk_cancellations;

end tkt_cancellation_dispatch;
/
