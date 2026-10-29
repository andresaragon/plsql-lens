




create or replace package body res_kitchen_routing as

  procedure route_kitchen_ticket(p_order_id in number, p_station in varchar2) is
    l_table_name varchar2(60);
    l_sql        varchar2(500);
    l_table_num  number;
    l_status     varchar2(20);
  begin
    l_table_name := 'kitchen_queue_' || p_station;
    l_sql := 'insert into ' || l_table_name || ' (order_id, queued_at) values (:oid, sysdate)';
    execute immediate l_sql using p_order_id;

    begin
      select table_number into l_table_num from customer_orders where order_id = p_order_id;
      update kitchen_display set table_no = l_table_num where order_id = p_order_id;
    exception
      when dup_val_on_index then
        null;
      when others then
        l_status := 'ERR';
    end;

    insert into order_routing_log(order_id, station_name, logged_time)
    values (p_order_id, p_station, sysdate);
  end route_kitchen_ticket;

  procedure close_table_session(p_session_id in number, p_date_str in varchar2, p_total out number) is
    type t_item_list is table of number;
    l_items      t_item_list;
    l_safe_table varchar2(60);
    l_sql        varchar2(400);
    l_order_date date;
    l_sum        number := 0;
    l_tax        number := 0;
  begin
    l_safe_table := dbms_assert.sql_object_name('orders_archive_current');
    l_sql := 'select nvl(sum(price), 0) from ' || l_safe_table || ' where session_id = :s';
    execute immediate l_sql into l_sum using p_session_id;

    l_order_date := to_date(p_date_str, 'YYYY-MM-DD');

    select item_id bulk collect into l_items from session_items where session_id = p_session_id;
    if l_items.count > 0 then
      forall i in 1 .. l_items.count
        update session_items set settled = 1 where item_id = l_items(i);
    end if;

    l_tax := round(l_sum * 0.08, 2);
    p_total := l_sum + l_tax;
  end close_table_session;

  function verify_station_status(p_station_code in varchar2) return varchar2 is
    l_status varchar2(20);
    l_ready  boolean := false;
  begin
    execute immediate get_station_query(p_station_code) into l_status;
    if l_status = 'ONLINE' then
      l_ready := true;
    end if;
    return l_status;
  end verify_station_status;

end res_kitchen_routing;
/
