create or replace package test_pkg_orders_apply_bulk_discount as
  --%suite(pkg_orders.apply_bulk_discount)

  --%test(NULL percentage raises ORA-20014)
  --%throws(-20014)
  procedure null_pct_raises;

  --%test(Zero percentage raises ORA-20014)
  --%throws(-20014)
  procedure zero_pct_raises;

  --%test(Negative percentage raises ORA-20014)
  --%throws(-20014)
  procedure negative_pct_raises;

  --%test(Percentage just above 50 raises ORA-20014)
  --%throws(-20014)
  procedure just_above_50_raises;

  --%test(Percentage 100 raises ORA-20014)
  --%throws(-20014)
  procedure pct_100_raises;

  --%test(Invalid percentage leaves prices unchanged)
  procedure invalid_pct_no_change;

  --%test(10 percent discount lowers the price)
  procedure normal_discount;

  --%test(Upper boundary 50 percent is accepted)
  procedure upper_boundary_50;

  --%test(Small percentage 0.01 is accepted and rounded)
  procedure lower_boundary_small;

  --%test(Result is rounded to 2 decimals)
  procedure rounding_two_decimals;

  --%test(Rounding of half cent at 50 percent)
  procedure rounding_half_cent;

  --%test(Return value counts all lines of NEW orders)
  procedure returns_count_of_new_lines;

  --%test(Every line of an order is discounted)
  procedure multiple_lines_all_discounted;

  --%test(PAID order lines are not changed)
  procedure paid_order_untouched;

  --%test(CANCELLED order lines are not changed)
  procedure cancelled_order_untouched;

  --%test(NEW order without items does not change the count)
  procedure order_without_items;

  --%test(Zero priced line stays zero but is counted)
  procedure zero_price_line;

  --%test(Quantity is not changed)
  procedure qty_unchanged;
end test_pkg_orders_apply_bulk_discount;
/
create or replace package body test_pkg_orders_apply_bulk_discount as

  function new_lines return pls_integer is
    l_cnt pls_integer;
  begin
    select count(*) into l_cnt
      from tg_order_items i join tg_orders o on o.order_id = i.order_id
     where o.status = 'NEW';
    return l_cnt;
  end new_lines;

  function mk_order(p_status varchar2, p_sku varchar2, p_qty number, p_price number) return number is
    l_id number;
  begin
    pkg_orders.create_order('UT customer', l_id);
    pkg_orders.add_item(l_id, p_sku, p_qty, p_price);
    if p_status <> 'NEW' then
      update tg_orders set status = p_status where order_id = l_id;
    end if;
    return l_id;
  end mk_order;

  function price_of(p_order_id number, p_sku varchar2) return number is
    l_price number;
  begin
    select unit_price into l_price from tg_order_items
     where order_id = p_order_id and sku = p_sku;
    return l_price;
  end price_of;

  procedure null_pct_raises is
    l_n pls_integer;
  begin
    l_n := pkg_orders.apply_bulk_discount(null);
  end null_pct_raises;

  procedure zero_pct_raises is
    l_n pls_integer;
  begin
    l_n := pkg_orders.apply_bulk_discount(0);
  end zero_pct_raises;

  procedure negative_pct_raises is
    l_n pls_integer;
  begin
    l_n := pkg_orders.apply_bulk_discount(-5);
  end negative_pct_raises;

  procedure just_above_50_raises is
    l_n pls_integer;
  begin
    l_n := pkg_orders.apply_bulk_discount(50.01);
  end just_above_50_raises;

  procedure pct_100_raises is
    l_n pls_integer;
  begin
    l_n := pkg_orders.apply_bulk_discount(100);
  end pct_100_raises;

  procedure invalid_pct_no_change is
    l_id    number;
    l_n     pls_integer;
    l_code  number := 0;
  begin
    l_id := mk_order('NEW', 'UT-INV', 1, 100);
    begin
      l_n := pkg_orders.apply_bulk_discount(51);
    exception
      when others then
        l_code := sqlcode;
    end;
    ut.expect(l_code).to_equal(-20014);
    ut.expect(price_of(l_id, 'UT-INV')).to_equal(100);
  end invalid_pct_no_change;

  procedure normal_discount is
    l_id number;
    l_n  pls_integer;
  begin
    l_id := mk_order('NEW', 'UT-A', 2, 200);
    l_n  := pkg_orders.apply_bulk_discount(10);
    ut.expect(price_of(l_id, 'UT-A')).to_equal(180);
  end normal_discount;

  procedure upper_boundary_50 is
    l_id number;
    l_n  pls_integer;
  begin
    l_id := mk_order('NEW', 'UT-50', 1, 100);
    l_n  := pkg_orders.apply_bulk_discount(50);
    ut.expect(price_of(l_id, 'UT-50')).to_equal(50);
  end upper_boundary_50;

  procedure lower_boundary_small is
    l_id number;
    l_n  pls_integer;
  begin
    l_id := mk_order('NEW', 'UT-S', 1, 100);
    l_n  := pkg_orders.apply_bulk_discount(0.01);
    ut.expect(price_of(l_id, 'UT-S')).to_equal(99.99);
  end lower_boundary_small;

  procedure rounding_two_decimals is
    l_id number;
    l_n  pls_integer;
  begin
    -- 10.05 * 0.85 = 8.5425 -> 8.54
    l_id := mk_order('NEW', 'UT-R', 1, 10.05);
    l_n  := pkg_orders.apply_bulk_discount(15);
    ut.expect(price_of(l_id, 'UT-R')).to_equal(8.54);
  end rounding_two_decimals;

  procedure rounding_half_cent is
    l_id number;
    l_n  pls_integer;
  begin
    -- 0.01 * 0.5 = 0.005 -> 0.01
    l_id := mk_order('NEW', 'UT-H', 1, 0.01);
    l_n  := pkg_orders.apply_bulk_discount(50);
    ut.expect(price_of(l_id, 'UT-H')).to_equal(0.01);
  end rounding_half_cent;

  procedure returns_count_of_new_lines is
    l_id1      number;
    l_id2      number;
    l_expected pls_integer;
    l_n        pls_integer;
  begin
    l_id1 := mk_order('NEW', 'UT-C1', 1, 10);
    l_id2 := mk_order('NEW', 'UT-C2', 3, 20);
    l_expected := new_lines;
    l_n := pkg_orders.apply_bulk_discount(5);
    ut.expect(l_n).to_equal(l_expected);
    ut.expect(l_n).to_be_greater_than(1);
  end returns_count_of_new_lines;

  procedure multiple_lines_all_discounted is
    l_id number;
    l_n  pls_integer;
  begin
    l_id := mk_order('NEW', 'UT-M1', 1, 100);
    pkg_orders.add_item(l_id, 'UT-M2', 5, 40);
    l_n := pkg_orders.apply_bulk_discount(25);
    ut.expect(price_of(l_id, 'UT-M1')).to_equal(75);
    ut.expect(price_of(l_id, 'UT-M2')).to_equal(30);
  end multiple_lines_all_discounted;

  procedure paid_order_untouched is
    l_id       number;
    l_expected pls_integer;
    l_n        pls_integer;
  begin
    l_id := mk_order('PAID', 'UT-P', 1, 100);
    l_expected := new_lines;
    l_n := pkg_orders.apply_bulk_discount(20);
    ut.expect(price_of(l_id, 'UT-P')).to_equal(100);
    ut.expect(l_n).to_equal(l_expected);
  end paid_order_untouched;

  procedure cancelled_order_untouched is
    l_id       number;
    l_expected pls_integer;
    l_n        pls_integer;
  begin
    l_id := mk_order('CANCELLED', 'UT-X', 1, 100);
    l_expected := new_lines;
    l_n := pkg_orders.apply_bulk_discount(20);
    ut.expect(price_of(l_id, 'UT-X')).to_equal(100);
    ut.expect(l_n).to_equal(l_expected);
  end cancelled_order_untouched;

  procedure order_without_items is
    l_id       number;
    l_expected pls_integer;
    l_n        pls_integer;
  begin
    pkg_orders.create_order('UT empty', l_id);
    l_expected := new_lines;
    l_n := pkg_orders.apply_bulk_discount(10);
    ut.expect(l_n).to_equal(l_expected);
    ut.expect(pkg_orders.order_total(l_id)).to_equal(0);
  end order_without_items;

  procedure zero_price_line is
    l_id       number;
    l_expected pls_integer;
    l_n        pls_integer;
  begin
    l_id := mk_order('NEW', 'UT-Z', 1, 0);
    l_expected := new_lines;
    l_n := pkg_orders.apply_bulk_discount(10);
    ut.expect(price_of(l_id, 'UT-Z')).to_equal(0);
    ut.expect(l_n).to_equal(l_expected);
  end zero_price_line;

  procedure qty_unchanged is
    l_id  number;
    l_n   pls_integer;
    l_qty number;
  begin
    l_id := mk_order('NEW', 'UT-Q', 7, 100);
    l_n  := pkg_orders.apply_bulk_discount(10);
    select qty into l_qty from tg_order_items where order_id = l_id and sku = 'UT-Q';
    ut.expect(l_qty).to_equal(7);
  end qty_unchanged;
end test_pkg_orders_apply_bulk_discount;
/
