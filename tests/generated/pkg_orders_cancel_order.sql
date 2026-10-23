create or replace package test_pkg_orders_cancel_order as
  --%suite(pkg_orders.cancel_order)

  --%test(Cancels a NEW order)
  procedure cancel_new_order;

  --%test(Cancels a PAID order)
  procedure cancel_paid_order;

  --%test(Cancelling does not change other orders)
  procedure cancel_leaves_other_orders;

  --%test(Cancelling does not change customer or created_at)
  procedure cancel_keeps_other_columns;

  --%test(Already cancelled order raises ORA-20013)
  --%throws(-20013)
  procedure already_cancelled_raises;

  --%test(Cancelling twice raises ORA-20013 and status stays CANCELLED)
  --%throws(-20013)
  procedure cancel_twice_raises;

  --%test(Missing order raises ORA-20012)
  --%throws(-20012)
  procedure missing_order_raises;

  --%test(NULL order id raises ORA-20012)
  --%throws(-20012)
  procedure null_order_raises;

  --%test(Negative order id raises ORA-20012)
  --%throws(-20012)
  procedure negative_order_raises;

  --%test(Failed cancel of a missing order creates no rows)
  procedure missing_order_no_side_effects;
end test_pkg_orders_cancel_order;
/
create or replace package body test_pkg_orders_cancel_order as

  function new_order(p_status varchar2, p_customer varchar2 default 'UT customer') return number is
    l_id number;
  begin
    l_id := tg_order_seq.nextval;
    insert into tg_orders (order_id, customer, status)
    values (l_id, p_customer, p_status);
    return l_id;
  end new_order;

  function status_of(p_id number) return varchar2 is
    l_status tg_orders.status%type;
  begin
    select status into l_status from tg_orders where order_id = p_id;
    return l_status;
  end status_of;

  procedure cancel_new_order is
    l_id number := new_order('NEW');
  begin
    pkg_orders.cancel_order(l_id);
    ut.expect(status_of(l_id)).to_equal('CANCELLED');
  end cancel_new_order;

  procedure cancel_paid_order is
    l_id number := new_order('PAID');
  begin
    pkg_orders.cancel_order(l_id);
    ut.expect(status_of(l_id)).to_equal('CANCELLED');
  end cancel_paid_order;

  procedure cancel_leaves_other_orders is
    l_target number := new_order('NEW');
    l_other_new number := new_order('NEW');
    l_other_paid number := new_order('PAID');
  begin
    pkg_orders.cancel_order(l_target);
    ut.expect(status_of(l_target)).to_equal('CANCELLED');
    ut.expect(status_of(l_other_new)).to_equal('NEW');
    ut.expect(status_of(l_other_paid)).to_equal('PAID');
  end cancel_leaves_other_orders;

  procedure cancel_keeps_other_columns is
    l_id        number := new_order('PAID', 'Keep Me');
    l_created   date;
    l_created2  date;
    l_customer  tg_orders.customer%type;
  begin
    select created_at into l_created from tg_orders where order_id = l_id;
    pkg_orders.cancel_order(l_id);
    select customer, created_at into l_customer, l_created2
      from tg_orders where order_id = l_id;
    ut.expect(l_customer).to_equal('Keep Me');
    ut.expect(l_created2).to_equal(l_created);
  end cancel_keeps_other_columns;

  procedure already_cancelled_raises is
    l_id number := new_order('CANCELLED');
  begin
    pkg_orders.cancel_order(l_id);
  end already_cancelled_raises;

  procedure cancel_twice_raises is
    l_id number := new_order('NEW');
  begin
    pkg_orders.cancel_order(l_id);
    pkg_orders.cancel_order(l_id);
  end cancel_twice_raises;

  procedure missing_order_raises is
    l_id number;
  begin
    select nvl(max(order_id), 0) + 1000 into l_id from tg_orders;
    pkg_orders.cancel_order(l_id);
  end missing_order_raises;

  procedure null_order_raises is
  begin
    pkg_orders.cancel_order(null);
  end null_order_raises;

  procedure negative_order_raises is
  begin
    pkg_orders.cancel_order(-1);
  end negative_order_raises;

  procedure missing_order_no_side_effects is
    l_before pls_integer;
    l_after  pls_integer;
    l_cancelled_before pls_integer;
    l_cancelled_after  pls_integer;
    l_id number;
  begin
    select count(*), count(case when status = 'CANCELLED' then 1 end)
      into l_before, l_cancelled_before from tg_orders;
    select nvl(max(order_id), 0) + 1000 into l_id from tg_orders;
    begin
      pkg_orders.cancel_order(l_id);
      ut.fail('Expected ORA-20012');
    exception
      when others then
        ut.expect(sqlcode).to_equal(-20012);
    end;
    select count(*), count(case when status = 'CANCELLED' then 1 end)
      into l_after, l_cancelled_after from tg_orders;
    ut.expect(l_after).to_equal(l_before);
    ut.expect(l_cancelled_after).to_equal(l_cancelled_before);
  end missing_order_no_side_effects;

end test_pkg_orders_cancel_order;
/
