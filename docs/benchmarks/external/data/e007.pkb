




create or replace package body ret_order_workflow as

  procedure mark_store_order(p_order_id in number) is
  begin
    update store_orders set order_status = 'PENDING_APPROVAL' where order_id = p_order_id;
    insert into order_audit(order_id, action) values (p_order_id, 'PENDING_APPROVAL');
  end mark_store_order;

  procedure escalate_unapproved_order(p_order_id in number) is
    l_cnt number;
  begin
    update order_escalations set status = 'PENDING_APPROVAL' where order_id = p_order_id;
    select count(*) into l_cnt from store_orders where order_id = p_order_id;
  end escalate_unapproved_order;

end ret_order_workflow;
/
