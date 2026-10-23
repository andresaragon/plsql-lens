-- Written for this repo. Order handling over tg_orders / tg_order_items (see orders_tables.sql).
create or replace package pkg_orders as
  -- Creates a NEW order for p_customer (trimmed) and returns its id. Raises ORA-20010 for a blank customer.
  procedure create_order(p_customer varchar2, p_order_id out number);
  -- Adds a line to a NEW order. Raises ORA-20011 when the order does not exist or is not NEW.
  procedure add_item(p_order_id number, p_sku varchar2, p_qty number, p_unit_price number);
  -- Sum of qty * unit_price, 0 for an order without items. Raises ORA-20012 when the order does not exist.
  function order_total(p_order_id number) return number;
  -- NEW and PAID orders can be cancelled. Raises ORA-20012 (missing) or ORA-20013 (already cancelled).
  procedure cancel_order(p_order_id number);
  -- Cursor over the ids of NEW and PAID orders, oldest first (order_id ascending).
  function open_orders return sys_refcursor;
  -- Lowers unit_price by p_pct percent on every line of NEW orders; returns the number of lines changed.
  -- Raises ORA-20014 unless 0 < p_pct <= 50.
  function apply_bulk_discount(p_pct number) return pls_integer;
end pkg_orders;
/
create or replace package body pkg_orders as
  procedure create_order(p_customer varchar2, p_order_id out number) is
  begin
    if trim(p_customer) is null then
      raise_application_error(-20010, 'customer is required');
    end if;
    p_order_id := tg_order_seq.nextval;
    insert into tg_orders (order_id, customer) values (p_order_id, trim(p_customer));
  end create_order;

  procedure add_item(p_order_id number, p_sku varchar2, p_qty number, p_unit_price number) is
    l_status tg_orders.status%type;
  begin
    begin
      select status into l_status from tg_orders where order_id = p_order_id;
    exception
      when no_data_found then
        raise_application_error(-20011, 'order not found');
    end;
    if l_status <> 'NEW' then
      raise_application_error(-20011, 'order is not open');
    end if;
    insert into tg_order_items (order_id, sku, qty, unit_price)
    values (p_order_id, p_sku, p_qty, p_unit_price);
  end add_item;

  function order_total(p_order_id number) return number is
    l_exists pls_integer;
    l_total number;
  begin
    select count(*) into l_exists from tg_orders where order_id = p_order_id;
    if l_exists = 0 then
      raise_application_error(-20012, 'order not found');
    end if;
    select nvl(sum(qty * unit_price), 0) into l_total from tg_order_items where order_id = p_order_id;
    return l_total;
  end order_total;

  procedure cancel_order(p_order_id number) is
    l_status tg_orders.status%type;
  begin
    begin
      select status into l_status from tg_orders where order_id = p_order_id;
    exception
      when no_data_found then
        raise_application_error(-20012, 'order not found');
    end;
    if l_status = 'CANCELLED' then
      raise_application_error(-20013, 'order already cancelled');
    end if;
    update tg_orders set status = 'CANCELLED' where order_id = p_order_id;
  end cancel_order;

  function open_orders return sys_refcursor is
    l_cur sys_refcursor;
  begin
    open l_cur for
      select order_id from tg_orders where status in ('NEW', 'PAID') order by order_id;
    return l_cur;
  end open_orders;

  function apply_bulk_discount(p_pct number) return pls_integer is
    l_rows pls_integer := 0;
  begin
    if p_pct is null or p_pct <= 0 or p_pct > 50 then
      raise_application_error(-20014, 'discount must be in (0, 50]');
    end if;
    for r in (select i.item_id from tg_order_items i join tg_orders o on o.order_id = i.order_id
               where o.status = 'NEW') loop
      update tg_order_items set unit_price = round(unit_price * (100 - p_pct) / 100, 2)
       where item_id = r.item_id;
      l_rows := l_rows + 1;
    end loop;
    return l_rows;
  end apply_bulk_discount;
end pkg_orders;
/
