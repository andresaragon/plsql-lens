create or replace package test_pkg_orders_order_total as
  --%suite(pkg_orders.order_total)

  --%test(Returns 0 for an existing order without items)
  procedure no_items_returns_zero;

  --%test(Returns qty * unit_price for a single item)
  procedure single_item;

  --%test(Sums several items of the same order)
  procedure multiple_items_sum;

  --%test(Handles decimal unit prices exactly)
  procedure decimal_prices;

  --%test(Item with unit_price 0 contributes 0)
  procedure zero_price_item;

  --%test(Minimum quantity of 1 boundary)
  procedure min_quantity_boundary;

  --%test(Large qty and price boundary)
  procedure max_values_boundary;

  --%test(Items of other orders are not included)
  procedure ignores_other_orders;

  --%test(Cancelled order still returns its total)
  procedure cancelled_order_total;

  --%test(Paid order returns its total)
  procedure paid_order_total;

  --%test(Total reflects items added after a first call)
  procedure total_updates_after_add_item;

  --%test(Non-existent order raises ORA-20012)
  --%throws(-20012)
  procedure missing_order_raises;

  --%test(NULL order id raises ORA-20012)
  --%throws(-20012)
  procedure null_order_raises;

  --%test(Negative order id raises ORA-20012)
  --%throws(-20012)
  procedure negative_order_raises;
end test_pkg_orders_order_total;
/
create or replace package body test_pkg_orders_order_total as

  function new_order(p_customer varchar2 default 'UT customer') return number is
    l_id number;
  begin
    pkg_orders.create_order(p_customer, l_id);
    return l_id;
  end new_order;

  procedure no_items_returns_zero is
    l_id    number := new_order;
    l_total number;
  begin
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(0);
  end no_items_returns_zero;

  procedure single_item is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 4, 12.50);
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(50);
  end single_item;

  procedure multiple_items_sum is
    l_id       number := new_order;
    l_total    number;
    l_expected number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 2, 10);
    pkg_orders.add_item(l_id, 'SKU-B', 3, 5.5);
    pkg_orders.add_item(l_id, 'SKU-C', 1, 100);
    select sum(qty * unit_price) into l_expected from tg_order_items where order_id = l_id;
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(l_expected);
    ut.expect(l_total).to_equal(136.5);
  end multiple_items_sum;

  procedure decimal_prices is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 3, 19.99);
    pkg_orders.add_item(l_id, 'SKU-B', 2, 0.01);
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(59.99);
  end decimal_prices;

  procedure zero_price_item is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-FREE', 5, 0);
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(0);
  end zero_price_item;

  procedure min_quantity_boundary is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 0.01);
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(0.01);
  end min_quantity_boundary;

  procedure max_values_boundary is
    l_id       number := new_order;
    l_total    number;
    l_expected number := 999999 * 99999999.99;
  begin
    pkg_orders.add_item(l_id, 'SKU-MAX', 999999, 99999999.99);
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(l_expected);
  end max_values_boundary;

  procedure ignores_other_orders is
    l_id1 number := new_order('UT customer 1');
    l_id2 number := new_order('UT customer 2');
  begin
    pkg_orders.add_item(l_id1, 'SKU-A', 1, 10);
    pkg_orders.add_item(l_id2, 'SKU-B', 7, 100);
    ut.expect(pkg_orders.order_total(l_id1)).to_equal(10);
    ut.expect(pkg_orders.order_total(l_id2)).to_equal(700);
  end ignores_other_orders;

  procedure cancelled_order_total is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 2, 15);
    update tg_orders set status = 'CANCELLED' where order_id = l_id;
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(30);
  end cancelled_order_total;

  procedure paid_order_total is
    l_id    number := new_order;
    l_total number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 2, 15);
    update tg_orders set status = 'PAID' where order_id = l_id;
    l_total := pkg_orders.order_total(l_id);
    ut.expect(l_total).to_equal(30);
  end paid_order_total;

  procedure total_updates_after_add_item is
    l_id     number := new_order;
    l_first  number;
    l_second number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 10);
    l_first := pkg_orders.order_total(l_id);
    pkg_orders.add_item(l_id, 'SKU-B', 2, 20);
    l_second := pkg_orders.order_total(l_id);
    ut.expect(l_first).to_equal(10);
    ut.expect(l_second).to_equal(50);
  end total_updates_after_add_item;

  procedure missing_order_raises is
    l_missing number;
    l_total   number;
  begin
    select nvl(max(order_id), 0) + 1000000 into l_missing from tg_orders;
    l_total := pkg_orders.order_total(l_missing);
    ut.fail('Expected ORA-20012 was not raised');
  end missing_order_raises;

  procedure null_order_raises is
    l_total number;
  begin
    l_total := pkg_orders.order_total(null);
    ut.fail('Expected ORA-20012 was not raised');
  end null_order_raises;

  procedure negative_order_raises is
    l_total number;
  begin
    l_total := pkg_orders.order_total(-1);
    ut.fail('Expected ORA-20012 was not raised');
  end negative_order_raises;

end test_pkg_orders_order_total;
/
