create or replace package test_pkg_orders_open_orders as
  --%suite(pkg_orders.open_orders)

  --%test(Returns an open cursor)
  procedure returns_open_cursor;

  --%test(Includes NEW and PAID orders and excludes CANCELLED ones)
  procedure includes_new_paid_excludes_cancelled;

  --%test(Result matches an independent query, in the same order)
  procedure matches_independent_query;

  --%test(Ids are returned in ascending order)
  procedure ids_ascending;

  --%test(Cursor is empty when every order is CANCELLED)
  procedure empty_when_all_cancelled;

  --%test(Boundary: exactly one open order is returned alone)
  procedure single_open_order;

  --%test(Order created through create_order is included)
  procedure created_order_included;

  --%test(Order cancelled through cancel_order is no longer returned)
  procedure cancelled_order_removed;
end test_pkg_orders_open_orders;
/
create or replace package body test_pkg_orders_open_orders as

  function insert_order(p_status varchar2) return number is
    l_id number;
  begin
    l_id := tg_order_seq.nextval;
    insert into tg_orders (order_id, customer, status)
    values (l_id, 'UT customer', p_status);
    return l_id;
  end insert_order;

  function fetch_ids(p_cur in out sys_refcursor) return sys.odcinumberlist is
    l_ids sys.odcinumberlist := sys.odcinumberlist();
    l_id  number;
  begin
    loop
      fetch p_cur into l_id;
      exit when p_cur%notfound;
      l_ids.extend;
      l_ids(l_ids.count) := l_id;
    end loop;
    close p_cur;
    return l_ids;
  end fetch_ids;

  function contains_id(p_ids sys.odcinumberlist, p_id number) return boolean is
  begin
    for i in 1 .. p_ids.count loop
      if p_ids(i) = p_id then
        return true;
      end if;
    end loop;
    return false;
  end contains_id;

  procedure cancel_all is
  begin
    update tg_orders set status = 'CANCELLED';
  end cancel_all;

  procedure returns_open_cursor is
    l_cur  sys_refcursor;
    l_open boolean;
  begin
    l_cur  := pkg_orders.open_orders;
    l_open := l_cur%isopen;
    ut.expect(l_open).to_be_true();
    close l_cur;
  end returns_open_cursor;

  procedure includes_new_paid_excludes_cancelled is
    l_new  number := insert_order('NEW');
    l_paid number := insert_order('PAID');
    l_canc number := insert_order('CANCELLED');
    l_cur  sys_refcursor;
    l_ids  sys.odcinumberlist;
  begin
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(contains_id(l_ids, l_new)).to_be_true();
    ut.expect(contains_id(l_ids, l_paid)).to_be_true();
    ut.expect(contains_id(l_ids, l_canc)).to_be_false();
  end includes_new_paid_excludes_cancelled;

  procedure matches_independent_query is
    l_dummy1 number := insert_order('NEW');
    l_dummy2 number := insert_order('PAID');
    l_dummy3 number := insert_order('CANCELLED');
    l_cur      sys_refcursor;
    l_ids      sys.odcinumberlist;
    l_actual   varchar2(32767);
    l_expected varchar2(32767);
  begin
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    for i in 1 .. l_ids.count loop
      l_actual := l_actual || l_ids(i) || ',';
    end loop;
    for r in (select order_id from tg_orders
               where status in ('NEW', 'PAID') order by order_id) loop
      l_expected := l_expected || r.order_id || ',';
    end loop;
    ut.expect(l_actual).to_equal(l_expected);
  end matches_independent_query;

  procedure ids_ascending is
    l_a   number := insert_order('NEW');
    l_b   number := insert_order('PAID');
    l_c   number := insert_order('NEW');
    l_cur sys_refcursor;
    l_ids sys.odcinumberlist;
    l_ok  boolean := true;
  begin
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(l_ids.count).to_be_greater_or_equal(3);
    for i in 2 .. l_ids.count loop
      if l_ids(i) <= l_ids(i - 1) then
        l_ok := false;
      end if;
    end loop;
    ut.expect(l_ok).to_be_true();
  end ids_ascending;

  procedure empty_when_all_cancelled is
    l_id  number := insert_order('NEW');
    l_cur sys_refcursor;
    l_ids sys.odcinumberlist;
  begin
    cancel_all;
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(l_ids.count).to_equal(0);
  end empty_when_all_cancelled;

  procedure single_open_order is
    l_id  number;
    l_cur sys_refcursor;
    l_ids sys.odcinumberlist;
  begin
    cancel_all;
    l_id  := insert_order('PAID');
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(l_ids.count).to_equal(1);
    ut.expect(l_ids(1)).to_equal(l_id);
  end single_open_order;

  procedure created_order_included is
    l_id  number;
    l_cur sys_refcursor;
    l_ids sys.odcinumberlist;
  begin
    pkg_orders.create_order('UT customer', l_id);
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(contains_id(l_ids, l_id)).to_be_true();
  end created_order_included;

  procedure cancelled_order_removed is
    l_id  number;
    l_cur sys_refcursor;
    l_ids sys.odcinumberlist;
  begin
    pkg_orders.create_order('UT customer', l_id);
    pkg_orders.cancel_order(l_id);
    l_cur := pkg_orders.open_orders;
    l_ids := fetch_ids(l_cur);
    ut.expect(contains_id(l_ids, l_id)).to_be_false();
  end cancelled_order_removed;

end test_pkg_orders_open_orders;
/
