create or replace package test_pkg_orders_create_order as
  --%suite(pkg_orders.create_order)

  --%test(Creates an order and returns a non-null id)
  procedure returns_id;

  --%test(Inserts exactly one row with the returned id and the customer)
  procedure inserts_row;

  --%test(New order has status NEW and a created_at date)
  procedure default_status_and_date;

  --%test(Customer is trimmed before being stored)
  procedure customer_is_trimmed;

  --%test(Two calls return different ids and create two rows)
  procedure distinct_ids;

  --%test(Customer of exactly 50 characters is accepted)
  procedure customer_max_length;

  --%test(Customer of 50 characters padded with spaces is accepted after trim)
  procedure customer_padded_to_max;

  --%test(Customer longer than 50 characters fails with value too large)
  --%throws(-12899)
  procedure customer_too_long;

  --%test(NULL customer raises ORA-20010)
  --%throws(-20010)
  procedure null_customer;

  --%test(Empty customer raises ORA-20010)
  --%throws(-20010)
  procedure empty_customer;

  --%test(Blank customer raises ORA-20010)
  --%throws(-20010)
  procedure blank_customer;

  --%test(Failed call inserts no row and leaves out id null)
  procedure error_inserts_nothing;
end test_pkg_orders_create_order;
/
create or replace package body test_pkg_orders_create_order as

  procedure returns_id is
    l_id number;
  begin
    pkg_orders.create_order('Alice', l_id);
    ut.expect(l_id).to_be_not_null();
  end returns_id;

  procedure inserts_row is
    l_id    number;
    l_count number;
    l_cust  tg_orders.customer%type;
  begin
    pkg_orders.create_order('Alice', l_id);
    select count(*), max(customer)
      into l_count, l_cust
      from tg_orders
     where order_id = l_id;
    ut.expect(l_count).to_equal(1);
    ut.expect(l_cust).to_equal('Alice');
  end inserts_row;

  procedure default_status_and_date is
    l_id     number;
    l_status tg_orders.status%type;
    l_date   tg_orders.created_at%type;
  begin
    pkg_orders.create_order('Bob', l_id);
    select status, created_at into l_status, l_date
      from tg_orders where order_id = l_id;
    ut.expect(l_status).to_equal('NEW');
    ut.expect(l_date).to_be_not_null();
  end default_status_and_date;

  procedure customer_is_trimmed is
    l_id   number;
    l_cust tg_orders.customer%type;
  begin
    pkg_orders.create_order('   Carol Smith   ', l_id);
    select customer into l_cust from tg_orders where order_id = l_id;
    ut.expect(l_cust).to_equal('Carol Smith');
  end customer_is_trimmed;

  procedure distinct_ids is
    l_id1   number;
    l_id2   number;
    l_count number;
  begin
    pkg_orders.create_order('Dave', l_id1);
    pkg_orders.create_order('Dave', l_id2);
    ut.expect(l_id2).to_be_not_null();
    ut.expect(l_id2).not_to_equal(l_id1);
    select count(*) into l_count
      from tg_orders where order_id in (l_id1, l_id2);
    ut.expect(l_count).to_equal(2);
  end distinct_ids;

  procedure customer_max_length is
    l_id   number;
    l_name varchar2(50) := rpad('x', 50, 'x');
    l_cust tg_orders.customer%type;
  begin
    pkg_orders.create_order(l_name, l_id);
    select customer into l_cust from tg_orders where order_id = l_id;
    ut.expect(l_cust).to_equal(l_name);
    ut.expect(length(l_cust)).to_equal(50);
  end customer_max_length;

  procedure customer_padded_to_max is
    l_id   number;
    l_name varchar2(50) := rpad('y', 50, 'y');
    l_cust tg_orders.customer%type;
  begin
    pkg_orders.create_order('  ' || l_name || '  ', l_id);
    select customer into l_cust from tg_orders where order_id = l_id;
    ut.expect(l_cust).to_equal(l_name);
  end customer_padded_to_max;

  procedure customer_too_long is
    l_id number;
  begin
    pkg_orders.create_order(rpad('z', 51, 'z'), l_id);
  end customer_too_long;

  procedure null_customer is
    l_id number;
  begin
    pkg_orders.create_order(null, l_id);
  end null_customer;

  procedure empty_customer is
    l_id number;
  begin
    pkg_orders.create_order('', l_id);
  end empty_customer;

  procedure blank_customer is
    l_id number;
  begin
    pkg_orders.create_order('     ', l_id);
  end blank_customer;

  procedure error_inserts_nothing is
    l_id     number;
    l_before number;
    l_after  number;
    l_code   number := 0;
  begin
    select count(*) into l_before from tg_orders;
    begin
      pkg_orders.create_order('   ', l_id);
    exception
      when others then
        l_code := sqlcode;
    end;
    select count(*) into l_after from tg_orders;
    ut.expect(l_code).to_equal(-20010);
    ut.expect(l_id).to_be_null();
    ut.expect(l_after).to_equal(l_before);
  end error_inserts_nothing;

end test_pkg_orders_create_order;
/
