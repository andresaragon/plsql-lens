create or replace package test_pkg_orders_add_item as
  --%suite(pkg_orders.add_item)

  --%test(Adds a line to a NEW order with the given values)
  procedure adds_line_to_new_order;

  --%test(Adds several lines to the same NEW order)
  procedure adds_multiple_lines;

  --%test(Does not touch lines of other orders)
  procedure does_not_affect_other_orders;

  --%test(Boundary: qty = 1 is accepted)
  procedure qty_min_boundary_ok;

  --%test(Boundary: qty = 999999 is accepted)
  procedure qty_max_boundary_ok;

  --%test(Boundary: unit_price = 0 is accepted)
  procedure unit_price_zero_ok;

  --%test(Boundary: unit_price = 99999999.99 is accepted)
  procedure unit_price_max_ok;

  --%test(Boundary: sku of 20 characters is accepted)
  procedure sku_max_length_ok;

  --%test(unit_price with 3 decimals is rounded to 2 decimals by the column)
  procedure unit_price_rounded_by_column;

  --%test(Non-existing order raises ORA-20011)
  --%throws(-20011)
  procedure order_not_found;

  --%test(Non-existing order message is order not found)
  procedure order_not_found_message;

  --%test(NULL order id raises ORA-20011)
  --%throws(-20011)
  procedure null_order_id;

  --%test(PAID order raises ORA-20011)
  --%throws(-20011)
  procedure paid_order_rejected;

  --%test(CANCELLED order raises ORA-20011)
  --%throws(-20011)
  procedure cancelled_order_rejected;

  --%test(Non open order message is order is not open)
  procedure not_open_message;

  --%test(Rejected add on PAID order inserts no line)
  procedure paid_order_no_line_inserted;

  --%test(NULL sku raises ORA-01400)
  --%throws(-1400)
  procedure null_sku;

  --%test(NULL qty raises ORA-01400)
  --%throws(-1400)
  procedure null_qty;

  --%test(NULL unit_price raises ORA-01400)
  --%throws(-1400)
  procedure null_unit_price;

  --%test(qty = 0 violates check constraint)
  --%throws(-2290)
  procedure qty_zero;

  --%test(Negative qty violates check constraint)
  --%throws(-2290)
  procedure qty_negative;

  --%test(Negative unit_price violates check constraint)
  --%throws(-2290)
  procedure unit_price_negative;

  --%test(qty = 1000000 exceeds NUMBER(6))
  --%throws(-1438)
  procedure qty_too_large;

  --%test(unit_price = 100000000 exceeds NUMBER(10,2))
  --%throws(-1438)
  procedure unit_price_too_large;

  --%test(sku of 21 characters exceeds column length)
  --%throws(-12899)
  procedure sku_too_long;
end test_pkg_orders_add_item;
/
create or replace package body test_pkg_orders_add_item as

  function new_order(p_status varchar2 default 'NEW') return number is
    l_id number;
  begin
    pkg_orders.create_order('Test customer', l_id);
    if p_status <> 'NEW' then
      update tg_orders set status = p_status where order_id = l_id;
    end if;
    return l_id;
  end new_order;

  function missing_order_id return number is
    l_id number;
  begin
    select nvl(max(order_id), 0) + 1000000 into l_id from tg_orders;
    return l_id;
  end missing_order_id;

  function item_count(p_order_id number) return number is
    l_cnt number;
  begin
    select count(*) into l_cnt from tg_order_items where order_id = p_order_id;
    return l_cnt;
  end item_count;

  procedure adds_line_to_new_order is
    l_id    number := new_order;
    l_sku   tg_order_items.sku%type;
    l_qty   number;
    l_price number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 3, 10.50);

    ut.expect(item_count(l_id)).to_equal(1);
    select sku, qty, unit_price into l_sku, l_qty, l_price
      from tg_order_items where order_id = l_id;
    ut.expect(l_sku).to_equal('SKU-A');
    ut.expect(l_qty).to_equal(3);
    ut.expect(l_price).to_equal(10.5);
  end adds_line_to_new_order;

  procedure adds_multiple_lines is
    l_id  number := new_order;
    l_sum number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 5);
    pkg_orders.add_item(l_id, 'SKU-B', 2, 7.25);
    pkg_orders.add_item(l_id, 'SKU-A', 4, 1);

    ut.expect(item_count(l_id)).to_equal(3);
    select sum(qty * unit_price) into l_sum from tg_order_items where order_id = l_id;
    ut.expect(l_sum).to_equal(23.5);
  end adds_multiple_lines;

  procedure does_not_affect_other_orders is
    l_id1 number := new_order;
    l_id2 number := new_order;
  begin
    pkg_orders.add_item(l_id1, 'SKU-A', 1, 1);

    ut.expect(item_count(l_id1)).to_equal(1);
    ut.expect(item_count(l_id2)).to_equal(0);
  end does_not_affect_other_orders;

  procedure qty_min_boundary_ok is
    l_id  number := new_order;
    l_qty number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 1);
    select qty into l_qty from tg_order_items where order_id = l_id;
    ut.expect(l_qty).to_equal(1);
  end qty_min_boundary_ok;

  procedure qty_max_boundary_ok is
    l_id  number := new_order;
    l_qty number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 999999, 1);
    select qty into l_qty from tg_order_items where order_id = l_id;
    ut.expect(l_qty).to_equal(999999);
  end qty_max_boundary_ok;

  procedure unit_price_zero_ok is
    l_id    number := new_order;
    l_price number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 0);
    select unit_price into l_price from tg_order_items where order_id = l_id;
    ut.expect(l_price).to_equal(0);
  end unit_price_zero_ok;

  procedure unit_price_max_ok is
    l_id    number := new_order;
    l_price number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 99999999.99);
    select unit_price into l_price from tg_order_items where order_id = l_id;
    ut.expect(l_price).to_equal(99999999.99);
  end unit_price_max_ok;

  procedure sku_max_length_ok is
    l_id  number := new_order;
    l_sku tg_order_items.sku%type;
  begin
    pkg_orders.add_item(l_id, rpad('X', 20, 'X'), 1, 1);
    select sku into l_sku from tg_order_items where order_id = l_id;
    ut.expect(l_sku).to_equal(rpad('X', 20, 'X'));
  end sku_max_length_ok;

  procedure unit_price_rounded_by_column is
    l_id    number := new_order;
    l_price number;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 2.346);
    select unit_price into l_price from tg_order_items where order_id = l_id;
    ut.expect(l_price).to_equal(2.35);
  end unit_price_rounded_by_column;

  procedure order_not_found is
  begin
    pkg_orders.add_item(missing_order_id, 'SKU-A', 1, 1);
  end order_not_found;

  procedure order_not_found_message is
    l_code number;
    l_msg  varchar2(4000);
  begin
    begin
      pkg_orders.add_item(missing_order_id, 'SKU-A', 1, 1);
    exception
      when others then
        l_code := sqlcode;
        l_msg  := sqlerrm;
    end;
    ut.expect(l_code).to_equal(-20011);
    ut.expect(l_msg).to_be_like('%order not found%');
  end order_not_found_message;

  procedure null_order_id is
  begin
    pkg_orders.add_item(null, 'SKU-A', 1, 1);
  end null_order_id;

  procedure paid_order_rejected is
    l_id number := new_order('PAID');
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 1);
  end paid_order_rejected;

  procedure cancelled_order_rejected is
    l_id number := new_order('CANCELLED');
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 1);
  end cancelled_order_rejected;

  procedure not_open_message is
    l_id   number := new_order('CANCELLED');
    l_code number;
    l_msg  varchar2(4000);
  begin
    begin
      pkg_orders.add_item(l_id, 'SKU-A', 1, 1);
    exception
      when others then
        l_code := sqlcode;
        l_msg  := sqlerrm;
    end;
    ut.expect(l_code).to_equal(-20011);
    ut.expect(l_msg).to_be_like('%order is not open%');
  end not_open_message;

  procedure paid_order_no_line_inserted is
    l_id   number := new_order('PAID');
    l_code number;
  begin
    begin
      pkg_orders.add_item(l_id, 'SKU-A', 1, 1);
    exception
      when others then
        l_code := sqlcode;
    end;
    ut.expect(l_code).to_equal(-20011);
    ut.expect(item_count(l_id)).to_equal(0);
  end paid_order_no_line_inserted;

  procedure null_sku is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, null, 1, 1);
  end null_sku;

  procedure null_qty is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', null, 1);
  end null_qty;

  procedure null_unit_price is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, null);
  end null_unit_price;

  procedure qty_zero is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 0, 1);
  end qty_zero;

  procedure qty_negative is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', -1, 1);
  end qty_negative;

  procedure unit_price_negative is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, -0.01);
  end unit_price_negative;

  procedure qty_too_large is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1000000, 1);
  end qty_too_large;

  procedure unit_price_too_large is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, 'SKU-A', 1, 100000000);
  end unit_price_too_large;

  procedure sku_too_long is
    l_id number := new_order;
  begin
    pkg_orders.add_item(l_id, rpad('X', 21, 'X'), 1, 1);
  end sku_too_long;

end test_pkg_orders_add_item;
/
